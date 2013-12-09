classdef ladderHandPlanner
  
  properties
    r
    atlas
    plan_pub
    posture_pub
    v
    left_hand_pt
    right_hand_pt
    left_hand_body;
    right_hand_body;
    left_joint_indices;
    right_joint_indices
    ik_options
    free_ik_options
    doVisualization = true;
    doPublish = false;
    default_axis_threshold = 3*pi/180;
    atlas2robotFrameIndMap
    lc
    state_monitor
    lcmgl
    left_hand_axis
    right_hand_axis
    lef
  end
  
  methods    
    function obj = ladderHandPlanner(r,atlas,left_hand_axis, left_hand_pt, right_hand_axis,right_hand_pt, ...
        doVisualization, doPublish)
      obj.atlas = atlas;
      obj.r = r;
      obj.doVisualization = doVisualization;
      if obj.doVisualization
        obj.v = obj.r.constructVisualizer;
        obj.v.playback_speed = 5;
      end
      obj.left_hand_axis = left_hand_axis;
      obj.right_hand_axis = right_hand_axis;
      obj.right_hand_pt = right_hand_pt;
      obj.left_hand_pt = left_hand_pt;
      
      
      l_hand_frame = handFrame(2,'left');
      r_hand_frame = handFrame(2,'right');
      obj.posture_pub = PosturePlanner(r,atlas,l_hand_frame,r_hand_frame,2);

      
      obj.doPublish = doPublish;
      
      joint_names = obj.atlas.getStateFrame.coordinates(1:getNumDOF(obj.atlas));
      joint_names = regexprep(joint_names, 'pelvis', 'base', 'preservecase'); % change 'pelvis' to 'base'
      
      obj.doPublish = doPublish;
      obj.plan_pub = RobotPlanPublisherWKeyFrames('CANDIDATE_MANIP_PLAN',true,joint_names);
      
      obj.right_hand_body = regexpIndex('r_hand',{r.getBody(:).linkname});
      obj.right_joint_indices = regexpIndex('^r_arm_[a-z]*[x-z]$',r.getStateFrame.coordinates);
      obj.left_hand_body = regexpIndex('l_hand',{r.getBody(:).linkname});
      obj.left_joint_indices = regexpIndex('^l_arm_[a-z]*[x-z]$',r.getStateFrame.coordinates);

      cost = ones(34,1);
      cost([1 2 6]) = 5000*ones(3,1);
      cost(3) = 200;
      
      vel_cost = cost*.05;
      accel_cost = cost*.05;

      obj.lc = lcm.lcm.LCM.getSingleton();
      obj.lcmgl = drake.util.BotLCMGLClient(obj.lc,'drill_planned_path');
      obj.state_monitor = drake.util.MessageMonitor(drc.robot_state_t, 'utime');
      obj.lc.subscribe('EST_ROBOT_STATE', obj.state_monitor);

      iktraj_options = IKoptions(obj.r);
      iktraj_options = iktraj_options.setDebug(true);
      iktraj_options = iktraj_options.setQ(diag(cost(1:getNumDOF(obj.r))));
      iktraj_options = iktraj_options.setQa(diag(vel_cost));
      iktraj_options = iktraj_options.setQv(diag(accel_cost));
      iktraj_options = iktraj_options.setqdf(zeros(obj.r.getNumDOF(),1),zeros(obj.r.getNumDOF(),1)); % upper and lower bnd on velocity.
      iktraj_options = iktraj_options.setMajorIterationsLimit(3000);
      iktraj_options = iktraj_options.setMex(true);
      iktraj_options = iktraj_options.setMajorOptimalityTolerance(1e-5);
      
      obj.ik_options = iktraj_options;
      obj.free_ik_options = iktraj_options.setFixInitialState(false);
            
      for i = 1:obj.atlas.getNumStates
        obj.atlas2robotFrameIndMap(i) = find(strcmp(obj.atlas.getStateFrame.coordinates{i},obj.r.getStateFrame.coordinates));
      end
    end
    
    function [xtraj, snopt_info, infeasible_constraint] = straightenLeftHand(obj, q0, ladder_axis)
      
      kinsol = obj.r.doKinematics(q0);
      
      % create posture constraint
      posture_index = setdiff((1:obj.r.num_q)',obj.left_joint_indices);
      posture_constraint = PostureConstraint(obj.r);
      posture_constraint = posture_constraint.setJointLimits(posture_index,q0(posture_index),q0(posture_index));
      
      % create hand position constraint
      ladder_z = [0;0;1];
      ladder_y = cross(ladder_z,ladder_axis);
      
      hand_pt_init = obj.r.forwardKin(kinsol,obj.left_hand_body,obj.left_hand_pt);
      o_T_f = [[ladder_axis ladder_y ladder_z] hand_pt_init; 0 0 0 1];
      hand_pos_constraint = WorldPositionInFrameConstraint(obj.r,obj.left_hand_body,obj.left_hand_pt,o_T_f,...
          [0;-.05;0],[0;.05;.1]);
      
      % create orientation constraint
      orientation_constraint = WorldGazeDirConstraint(obj.r,obj.left_hand_body,obj.left_hand_axis,...
        ladder_axis,obj.default_axis_threshold);
      
      [q_end_nom,snopt_info,infeasible_constraint] = inverseKin(obj.r,q0,q0,...
        hand_pos_constraint,orientation_constraint,posture_constraint,obj.ik_options);
      
      if(snopt_info > 10)
        send_msg = infeasibleConstraintMsg(infeasible_constraint);
        send_status(4,0,0,send_msg);
        warning(send_msg);
      end
      
      if obj.doPublish && snopt_info <= 10
        msg = drc.joint_angles_t;
        msg.robot_name = 'atlas';
        msg.num_joints = length(obj.left_joint_indices);
        msg.utime = etime(clock,[1970 1 1 0 0 0])*1e6;
        msg.joint_name = obj.r.getStateFrame.coordinates(obj.left_joint_indices);
        msg.joint_position = q_end_nom(obj.left_joint_indices);
        obj.lc.publish('POSTURE_GOAL',msg); 
        xtraj = q_end_nom;
      else
        xtraj = [];
      end
    end
    
    function [xtraj, snopt_info, infeasible_constraint] = straightenRightHand(obj, q0, ladder_axis)
      
      kinsol = obj.r.doKinematics(q0);
      
      % create posture constraint
      posture_index = setdiff((1:obj.r.num_q)',obj.right_joint_indices);
      posture_constraint = PostureConstraint(obj.r);
      posture_constraint = posture_constraint.setJointLimits(posture_index,q0(posture_index),q0(posture_index));
      
 
      % create hand position constraint
      ladder_z = [0;0;1];
      ladder_y = cross(ladder_z,ladder_axis);
      
      hand_pt_init = obj.r.forwardKin(kinsol,obj.right_hand_body,obj.right_hand_pt);
      o_T_f = [[ladder_axis ladder_y ladder_z] hand_pt_init; 0 0 0 1];
      hand_pos_constraint = WorldPositionInFrameConstraint(obj.r,obj.right_hand_body,obj.right_hand_pt,o_T_f,...
          [0;-.05;0],[0;.05;.1]);
      
      % create orientation constraint
      orientation_constraint = WorldGazeDirConstraint(obj.r,obj.right_hand_body,obj.right_hand_axis,...
        ladder_axis,obj.default_axis_threshold);
      
      [q_end_nom,snopt_info,infeasible_constraint] = inverseKin(obj.r,q0,q0,...
        hand_pos_constraint,orientation_constraint,posture_constraint,obj.ik_options);
      
      if(snopt_info > 10)
        send_msg = infeasibleConstraintMsg(infeasible_constraint);
        send_status(4,0,0,send_msg);
        warning(send_msg);
      end
      
      if obj.doPublish && snopt_info <= 10
        msg = drc.joint_angles_t;
        msg.robot_name = 'atlas';
        msg.num_joints = length(obj.right_joint_indices);
        msg.utime = etime(clock,[1970 1 1 0 0 0])*1e6;
        msg.joint_name = obj.r.getStateFrame.coordinates(obj.right_joint_indices);
        msg.joint_position = q_end_nom(obj.right_joint_indices);
        obj.lc.publish('POSTURE_GOAL',msg);
        xtraj = q_end_nom;
      else
        xtraj = [];
      end
    end
  end
end
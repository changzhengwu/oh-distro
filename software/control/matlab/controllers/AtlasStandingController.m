classdef AtlasStandingController < DRCController
  
  properties (SetAccess=protected,GetAccess=protected)
    robot;
    foot_idx;
    controller_state_dim;
  end
  
  methods
  
    function obj = AtlasStandingController(name,r,options)
      typecheck(r,'Atlas');

      if nargin < 3
        options = struct();
      end
      
      force_control_joint_str = {'leg'};% <---- cell array of (sub)strings  
      force_controlled_joints = [];
      for i=1:length(force_control_joint_str)
        force_controlled_joints = union(force_controlled_joints,find(~cellfun(@isempty,strfind(r.getInputFrame.coordinates,force_control_joint_str{i}))));
      end

      act_ind = (1:r.getNumInputs)';
      position_controlled_joints = setdiff(act_ind,force_controlled_joints);
      
      ctrl_data = SharedDataHandle(struct(...
        'is_time_varying',false,...
        'x0',zeros(4,1),...
        'support_times',0,...
        'supports',[],...
        'mu',1.0,...
        'trans_drift',[0;0;0],...
        'ignore_terrain',false,...
        'qtraj',zeros(getNumDOF(r),1),...
        'force_controlled_joints', force_controlled_joints,...
        'position_controlled_joints', position_controlled_joints,...
        'constrained_dofs',[findJointIndices(r,'arm');findJointIndices(r,'back');findJointIndices(r,'neck')]));
 
      sys = AtlasBalancingWrapper(r,ctrl_data,options);
      obj = obj@DRCController(name,sys,AtlasState(r));
 
      obj.controller_state_dim = sys.velocity_int_block.getStateFrame.dim;
      obj.robot = r;
      obj.controller_data = ctrl_data;
      obj.foot_idx = [r.findLinkInd('r_foot'),r.findLinkInd('l_foot')];

      % use saved nominal pose 
      d = load(strcat(getenv('DRC_PATH'),'/control/matlab/data/atlas_fp.mat'));
      q0 = d.xstar(1:getNumDOF(obj.robot));
      kinsol = doKinematics(obj.robot,q0);
      com = getCOM(obj.robot,kinsol);

      % build TI-ZMP controller 
      foot_cpos = terrainContactPositions(r,kinsol,obj.foot_idx);
      comgoal = mean([mean(foot_cpos(1:2,1:4)');mean(foot_cpos(1:2,5:8)')])';
      limp = LinearInvertedPendulum(com(3));
      K = lqr(limp,comgoal);
      
      supports = SupportState(r,[r.findLinkInd('r_foot'),r.findLinkInd('l_foot')]);
      
      obj.controller_data.setField('K',K);
      obj.controller_data.setField('qtraj',q0);
      obj.controller_data.setField('x0',[comgoal;0;0]);
      obj.controller_data.setField('y0',comgoal);
      obj.controller_data.setField('supports',supports);
      obj.controller_data.setField('firstplan',true);
      
      link_constraints(1).link_ndx = obj.foot_idx(1);
      link_constraints(1).pt = [0;0;0];
      link_constraints(1).pos = forwardKin(r,kinsol,obj.foot_idx(1),[0;0;0],1);
      link_constraints(2).link_ndx = obj.foot_idx(2);
      link_constraints(2).pt = [0;0;0];
      link_constraints(2).pos = forwardKin(r,kinsol,obj.foot_idx(2),[0;0;0],1);
      obj.controller_data.setField('link_constraints',link_constraints);

      obj = addLCMTransition(obj,'START_MIT_STAND',drc.utime_t(),'stand');  
      obj = addLCMTransition(obj,'ATLAS_BEHAVIOR_COMMAND',drc.atlas_behavior_command_t(),'init'); 
      obj = addLCMTransition(obj,'CONFIGURATION_TRAJ',drc.configuration_traj_t(),name); % for standing/reaching tasks

    end
    
    function msg = status_message(obj,t_sim,t_ctrl)
        msg = drc.controller_status_t();
        msg.utime = t_sim * 1000000;
        msg.state = msg.STANDING;
        msg.controller_utime = t_ctrl * 1000000;
        msg.V = 0;
        msg.Vdot = 0;
    end
    
    function obj = initialize(obj,data)
       if isfield(data,'CONFIGURATION_TRAJ')
        % standing and reaching plan
        try
          msg = data.CONFIGURATION_TRAJ;
          obj.controller_data.setField('qtraj',mxDeserialize(msg.qtraj));
        catch err
          standAtCurrentState(obj,data.AtlasState);
        end
      elseif isfield(data,'AtlasState')
        standAtCurrentState(obj,data.AtlasState);
      end
      obj = setDuration(obj,inf,false); % set the controller timeout
      controller_state = obj.controller_data.data.qd_int_state;
      controller_state(3) = 0; % reset time
      controller_state(4) = 0; % reset eta
      obj.controller_data.setField('qd_int_state',controller_state);
    end
    
    function standAtCurrentState(obj,x0)
      r = obj.robot;
      q0 = x0(1:getNumDOF(r));
      kinsol = doKinematics(r,q0);
      foot_cpos = terrainContactPositions(r,kinsol,obj.foot_idx);
      comgoal = mean([mean(foot_cpos(1:2,1:4)');mean(foot_cpos(1:2,5:8)')])';
      obj.controller_data.setField('qtraj',q0);
      obj.controller_data.setField('x0',[comgoal;0;0]);
      obj.controller_data.setField('y0',comgoal);
      obj.controller_data.setField('comtraj',comgoal);

      link_constraints(1).link_ndx = obj.foot_idx(1);
      link_constraints(1).pt = [0;0;0];
      link_constraints(1).pos = forwardKin(r,kinsol,obj.foot_idx(1),[0;0;0],1);
      link_constraints(2).link_ndx = obj.foot_idx(2);
      link_constraints(2).pt = [0;0;0];
      link_constraints(2).pos = forwardKin(r,kinsol,obj.foot_idx(2),[0;0;0],1);
      obj.controller_data.setField('link_constraints',link_constraints);
    end
  end
end

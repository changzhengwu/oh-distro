classdef AtlasState < LCMCoordinateFrameWCoder & Singleton
  
  methods
    function obj=AtlasState(r)
      typecheck(r,'TimeSteppingRigidBodyManipulator');

      obj = obj@LCMCoordinateFrameWCoder('AtlasState',r.getNumStates(),'x');
      obj = obj@Singleton();

      if isempty(obj.lcmcoder)  % otherwise I had a singleton
        joint_names = r.getStateFrame.coordinates(1:getNumDOF(r));
        coder = RobotStateCoder('atlas', joint_names);
      
        obj = setLCMCoder(obj,JLCMCoder(coder));
        obj.setCoordinateNames(r.getStateFrame.coordinates);
        obj.setDefaultChannel('EST_ROBOT_STATE');
      end

    if (obj.mex_ptr==0)
      obj.mex_ptr = SharedDataHandle(RobotStateMonitor('atlas',joint_names));
    end
    end

     function delete(obj)
       note that delete is also called on temporary objects used to
       recover the actual Singleton object
       if (obj.mex_ptr ~= 0)
         RobotStateMonitor(obj.mex_ptr.getData);
       end
     end
     
      function obj = subscribe(obj,channel)
        RobotStateMonitor(obj.mex_ptr.getData,0,channel);
      end
      
      function [x,t] = getNextMessage(obj,timeout)   % x=t=[] if timeout
        [x,t] = RobotStateMonitor(obj.mex_ptr.getData,1,timeout);
      end
      
      function [x,t] = getMessage(obj)
        [x,t] = RobotStateMonitor(obj.mex_ptr.getData,2);
      end
      
      function [x,t] = getCurrentValue(obj)
        [x,t] = RobotStateMonitor(obj.mex_ptr.getData,2);
      end
      
      function t = getLastTimestamp(obj)
        t = RobotStateMonitor(obj.mex_ptr.getData,3);
      end
      
      function markAsRead(obj)
        RobotStateMonitor(obj.mex_ptr.getData,4);
      end
  end
  
 properties
  mex_ptr=0
 end
end

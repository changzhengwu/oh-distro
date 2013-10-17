function [INS, Meas] = receiveInertialStatePos(aggregator)


while true
    %disp waiting
    millis_to_wait = 1;
    msg = aggregator.getNextMessage(millis_to_wait);
    if length(msg) > 0
        break
    end
end

m = drc.ins_update_request_t(msg.data);

INS.Pose.utime = m.utime;
INS.Pose.P_l = [m.pose.translation.x;m.pose.translation.y;m.pose.translation.z];
INS.Pose.V_l = [m.twist.linear_velocity.x;m.twist.linear_velocity.y;m.twist.linear_velocity.z];
INS.Pose.q = [m.pose.rotation.w;m.pose.rotation.x;m.pose.rotation.y;m.pose.rotation.z];
INS.Pose.w_l = [m.twist.angular_velocity.x;m.twist.angular_velocity.y;m.twist.angular_velocity.z];
INS.Pose.f_l = [m.local_linear_acceleration.x;m.local_linear_acceleration.y;m.local_linear_acceleration.z];

% referencePos_local
Meas.Pose.P_l = [m.referencePos_local.x;m.referencePos_local.y;m.referencePos_local.z];
Meas.Pose.V_l = [m.referenceVel_local.x;m.referenceVel_local.y;m.referenceVel_local.z];
Meas.Pose.V_b = [m.referenceVel_body.x;m.referenceVel_body.y;m.referenceVel_body.z];
Meas.Pose.q = [m.referenceQ_local.w;m.referenceQ_local.x;m.referenceQ_local.y;m.referenceQ_local.z];

Meas.updateType = m.updateType;


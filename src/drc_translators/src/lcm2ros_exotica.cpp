/*
 - Designer will publish:
 http://docs.ros.org/indigo/api/trajectory_msgs/html/msg/JointTrajectory.html
 - Designer will receive: (with root link as 0,0,0)
 http://docs.ros.org/indigo/api/sensor_msgs/html/msg/JointState.html
 */
#include <cstdlib>
#include <string>
#include <ros/ros.h>
#include <lcm/lcm-cpp.hpp>

#include "lcmtypes/drc/robot_plan_t.hpp"
#include "lcmtypes/drc/plan_control_t.hpp"
#include "lcmtypes/drc/affordance_collection_t.hpp"
#include "lcmtypes/drc/robot_state_t.hpp"
#include <trajectory_msgs/JointTrajectory.h>
#include <ipab_msgs/PlannerRequest.h>
#include <std_srvs/Empty.h>
#include <std_msgs/String.h>

#include "lcmtypes/ipab/exotica_planner_request_t.hpp"

using namespace std;

class LCM2ROS
{
public:
  LCM2ROS(boost::shared_ptr<lcm::LCM> &lcm_, ros::NodeHandle &nh_);
  ~LCM2ROS()
  {
  }

private:
  boost::shared_ptr<lcm::LCM> lcm_;
  ros::NodeHandle nh_;

  ros::Publisher planner_request_pub_;
  ros::Publisher ik_request_pub_;

  void plannerRequestHandler(const lcm::ReceiveBuffer* rbuf, const std::string &channel,
                             const ipab::exotica_planner_request_t* msg);
  void ikRequestHandler(const lcm::ReceiveBuffer* rbuf, const std::string &channel,
                        const ipab::exotica_planner_request_t* msg);

};

LCM2ROS::LCM2ROS(boost::shared_ptr<lcm::LCM> &lcm_, ros::NodeHandle &nh_) :
    lcm_(lcm_), nh_(nh_)
{
  lcm_->subscribe("PLANNER_REQUEST", &LCM2ROS::plannerRequestHandler, this);
  planner_request_pub_ = nh_.advertise<ipab_msgs::PlannerRequest>("/exotica/planner_request", 10);

  lcm_->subscribe("IK_REQUEST", &LCM2ROS::ikRequestHandler, this);
  ik_request_pub_ = nh_.advertise<ipab_msgs::PlannerRequest>("/exotica/ik_request", 10);
}

void translatePlannerRequest(const ipab::exotica_planner_request_t* msg, ipab_msgs::PlannerRequest& m)
{
  m.header.stamp = ros::Time().fromSec(msg->utime * 1E-6);
  m.poses = msg->poses;
  m.constraints = msg->constraints;
  m.affordances = msg->affordances;
  m.seed_pose = msg->seed_pose;
  m.nominal_pose = msg->nominal_pose;
  m.end_pose = msg->end_pose;
  m.joint_names = msg->joint_names;
  m.options = msg->options;
}

void LCM2ROS::plannerRequestHandler(const lcm::ReceiveBuffer* rbuf, const std::string &channel,
                                    const ipab::exotica_planner_request_t* msg)
{
  ROS_ERROR("LCM2ROS got PLANNER_REQUEST");
  ipab_msgs::PlannerRequest m;
  translatePlannerRequest(msg, m);
  planner_request_pub_.publish(m);
}

void LCM2ROS::ikRequestHandler(const lcm::ReceiveBuffer* rbuf, const std::string &channel,
                               const ipab::exotica_planner_request_t* msg)
{
  ROS_ERROR("LCM2ROS got IK_REQUEST");
  ipab_msgs::PlannerRequest m;
  translatePlannerRequest(msg, m);
  ik_request_pub_.publish(m);
}

int main(int argc, char** argv)
{
  ros::init(argc, argv, "lcm2ros", ros::init_options::NoSigintHandler);
  boost::shared_ptr<lcm::LCM> lcm(new lcm::LCM);
  if (!lcm->good())
  {
    std::cerr << "ERROR: lcm is not good()" << std::endl;
  }
  ros::NodeHandle nh;

  LCM2ROS handlerObject(lcm, nh);
  cout << "\nlcm2ros translator ready\n";
  ROS_ERROR("LCM2ROS Translator Ready");

  while (0 == lcm->handle())
    ;
  return 0;
}

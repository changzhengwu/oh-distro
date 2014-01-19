#include <octomap_utils/octomap_util.hpp>

#include <Eigen/Dense>
#include <Eigen/Geometry>
#include <eigen_utils/eigen_utils.hpp>

#include <mav_state_est/rbis.hpp>
#ifndef LASERLIKELIHOODINTERFACE_HPP_
#define LASERLIKELIHOODINTERFACE_HPP_

//TODO: static polymorphism?

class LaserLikelihoodInterface {
public:

  //returns POSITIVE log likelihood of the laser point
  virtual double evaluatePointLogLikelihood(const double point[3])=0;

  //returns POSITIVE log likelihood of the state given the measurement
  virtual double evaluateScanLogLikelihood(const laser_projected_scan * lscan, const RBIS & scan_to_map);

  double cov_scaling_factor; //scaling factor on covariance via dividing summed log likelihoods
  double minNegLogLike;
};

class OctomapLikelihoodInterface: public LaserLikelihoodInterface {
public:
  OctomapLikelihoodInterface(const char * map_name, double _unknown_loglike, double _information_scaling_factor);
  ~OctomapLikelihoodInterface();

  double evaluatePointLogLikelihood(const double point[3]);

  double unknown_loglike; //log-likelihood of an unknown cell in the map

  octomap::OcTree * ocTree;

  double minxyz[3];
  double maxxyz[3];
};


#endif /* LASERLIKELIHOODINTERFACE_HPP_ */

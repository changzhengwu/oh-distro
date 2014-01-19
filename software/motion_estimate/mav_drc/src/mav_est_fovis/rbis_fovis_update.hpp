#ifndef RBIS_FOVIS_LIB_UPDATE_HPP_
#define RBIS_FOVIS_LIB_UPDATE_HPP_

#include <lcm/lcm.h>
#include <bot_core/bot_core.h>
#include <bot_param/param_client.h>
#include <bot_frames/bot_frames.h>

#include <lcmtypes/fovis_bot2.hpp>

#include <mav_state_est/rbis_update_interface.hpp>
#include <mav_state_est/sensor_handlers.hpp>

namespace MavStateEst {

class FovisHandler {
public:
  // Typical mode is MODE_VELOCITY_ROT_RATE
  typedef enum {
    MODE_LIN_RATE, MODE_ROT_RATE, MODE_LIN_AND_ROT_RATE
  } FovisMode;

  FovisHandler(BotParam * param);

  RBISUpdateInterface * processMessage(const fovis::update_t  * msg);

  FovisMode mode;
  Eigen::VectorXi z_indices;
  Eigen::MatrixXd cov_fovis;

};


}
#endif /* RBIS_FOVIS_LIB_UPDATE_HPP_ */


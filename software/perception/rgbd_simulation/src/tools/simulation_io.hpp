#ifndef PCL_SIMULATION_IO_
#define PCL_SIMULATION_IO_

#include <boost/shared_ptr.hpp>

#include <GL/glew.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>

// define the following in order to eliminate the deprecated headers warning
#define VTK_EXCLUDE_STRSTREAM_HEADERS
#include <pcl/io/pcd_io.h>
#include <pcl/point_types.h>
#include <pcl/io/vtk_lib_io.h>


#include "rgbd_simulation/camera.h"
#include "rgbd_simulation/scene.h"
#include "rgbd_simulation/range_likelihood.h"

// Writing PNG files:
#include <opencv/cv.h>
#include <opencv/highgui.h>

using namespace pcl::simulation;

class SimExample
{
  public:
    typedef boost::shared_ptr<SimExample> Ptr;
    typedef boost::shared_ptr<const SimExample> ConstPtr;
	
    SimExample (int argc, char** argv,
		int height,int width);
    void initializeGL (int argc, char** argv);
    
    Scene::Ptr scene_;
    Camera::Ptr camera_;
    RangeLikelihood::Ptr rl_;  

    void doSim (Eigen::Isometry3d pose_in);

    void write_score_image(const float* score_buffer,std::string fname);
    void write_depth_image(const float* depth_buffer,std::string fname);
    void write_depth_image_uint(const float* depth_buffer,std::string fname);
    void write_rgb_image(const uint8_t* rgb_buffer,std::string fname);

  private:
    uint16_t t_gamma[2048];  

    // of platter, usually 640x480
    int width_;
    int height_;
};




#endif

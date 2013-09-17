# This script is executed in the main console namespace so
# that all the variables defined here become console variables.


import vtk
from PythonQt import QtCore, QtGui
import ddapp.applogic as app
from ddapp import matlab
from ddapp import jointcontrol
from ddapp import cameracontrol
from ddapp import ik
import numpy as np



quit = app.quit
exit = quit

app.startup(globals())

model = app.loadTestModel()
jc = jointcontrol.JointController(model)
jc.addNominalPoseFromFile(app.getNominalPoseMatFile())
jc.setNominalPose()

view = app.getDRCView()
camera = view.camera()

camera.SetFocalPoint([0,0,0])
camera.SetPosition([1, 0, 0])
camera.SetViewUp([0,0,1])
view.resetCamera()

orbit = cameracontrol.OrbitController(view)



s = ik.AsyncIKCommunicator(model)
s.start()
s.startServerAsync()


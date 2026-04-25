#pragma once

#ifdef NO_BLE
// Disponible uniquement en build Wokwi (-DNO_BLE).
// Lit des lignes JSON depuis Serial et les pousse dans qCalibCmd.
// Protocole identique au BLE opérationnel :
//   {"cmd":"tare"}
//   {"cmd":"calibrate","kg":1.000}
//   {"cmd":"adjust","dir":"+"}
//   {"cmd":"adjust","dir":"-"}
void startTaskCalibSerial();
#endif

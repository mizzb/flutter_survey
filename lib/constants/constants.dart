library constants;

const String app_tittle = "Queberry";
const String discovery_service = "_http._tcp";
const String halo_title = "queberry-halo";

///API's
const String api_device_status = "/api/device";
const String api_device_register = "/api/devices/register";
const String api_device_survey = "/api/device/survey";
const String api_signage_config = "/api/signage/config";
const String api_take_survey = "/survey/takeSurvey?survey=";
const String api_STOMP_config = "/notifications/config";
const String api_STOMP_device = "/notifications/signage/device";
const String api_STOMP_survey = "/notifications/survey/trigger";

/// MDNS
const String mdns_init = "INITIALISING";
const String mdns_discovered = "DISCOVERED";
const String mdns_resolved = "RESOLVED";
const String mdns_failed = "FAILED";
// mdns-ui
const String initialized = "initialized";
const String searching = "searching..";
const String resolving = "resolving..";
const String failed = "MDNS Failed";
const String something_wrong = "something went wrong";

/// HOME WIDGET
const String dev_reg_init = "Device registration in process";
const String dev_reg_completed = "Device Registered";
const String dev_reg_failed = "Device Registration failed. Restart the app";
const String dev_pair_init = "Checking device status";
const String dev_paired = "Device paired";
const String dev_pair_fail = "Device not paired. Please pair the device";

/// SURVEY WIDGET
const String dev_conn_init = "Connecting to Halo";
const String dev_conn_fail = "Cannot connect to the Halo";
const String dev_config_init = "Configuring the app";
const String dev_config_fail = "App configuration failed. Restart the app";
const String no_survey_assigned = "No survey assigned";
const String loading_survey = "Loading Survey";
const String survey_not_assigned = "Survey not assigned";
const String survey_disabled = "Survey not enabled";
const String survey_notAvlbl = "Survey not available";

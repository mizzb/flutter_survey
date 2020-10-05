// To parse this JSON data, do
//
//     final config = configFromJson(jsonString);

import 'dart:convert';

Config configFromJson(String str) => Config.fromJson(json.decode(str));

String configToJson(Config data) => json.encode(data.toJson());

class Config {
  Config({
    this.audio,
    this.dispenser,
    this.queue,
    this.theme,
    this.token,
    this.sms,
    this.survey,
    this.home,
    this.time,
    this.activeProfiles,
    this.mode,
  });

  Audio audio;
  Dispenser dispenser;
  Queue queue;
  Theme theme;
  Token token;
  Sms sms;
  SurveyConf survey;
  Home home;
  DateTime time;
  List<String> activeProfiles;
  String mode;

  factory Config.fromJson(Map<String, dynamic> json) => Config(
    audio: Audio.fromJson(json["audio"]),
    dispenser: Dispenser.fromJson(json["dispenser"]),
    queue: Queue.fromJson(json["queue"]),
    theme: Theme.fromJson(json["theme"]),
    token: Token.fromJson(json["token"]),
    sms: Sms.fromJson(json["sms"]),
    survey: SurveyConf.fromJson(json["survey"]),
    home: Home.fromJson(json["home"]),
    time: DateTime.parse(json["time"]),
    activeProfiles: List<String>.from(json["activeProfiles"].map((x) => x)),
    mode: json["mode"],
  );

  Map<String, dynamic> toJson() => {
    "audio": audio.toJson(),
    "dispenser": dispenser.toJson(),
    "queue": queue.toJson(),
    "theme": theme.toJson(),
    "token": token.toJson(),
    "sms": sms.toJson(),
    "survey": survey.toJson(),
    "home": home.toJson(),
    "time": time.toIso8601String(),
    "activeProfiles": List<dynamic>.from(activeProfiles.map((x) => x)),
    "mode": mode,
  };
}

class Audio {
  Audio({
    this.bell,
    this.announcement,
  });

  bool bell;
  bool announcement;

  factory Audio.fromJson(Map<String, dynamic> json) => Audio(
    bell: json["bell"],
    announcement: json["announcement"],
  );

  Map<String, dynamic> toJson() => {
    "bell": bell,
    "announcement": announcement,
  };
}

class Dispenser {
  Dispenser({
    this.welcomeMessage,
    this.numberOfTokens,
    this.showClock,
    this.messageAfterBusinessHours,
    this.blurBackground,
    this.enableServiceGroup,
    this.showBarcode,
  });

  String welcomeMessage;
  int numberOfTokens;
  bool showClock;
  String messageAfterBusinessHours;
  bool blurBackground;
  bool enableServiceGroup;
  bool showBarcode;

  factory Dispenser.fromJson(Map<String, dynamic> json) => Dispenser(
    welcomeMessage: json["welcomeMessage"],
    numberOfTokens: json["numberOfTokens"],
    showClock: json["showClock"],
    messageAfterBusinessHours: json["messageAfterBusinessHours"],
    blurBackground: json["blurBackground"],
    enableServiceGroup: json["enableServiceGroup"],
    showBarcode: json["showBarcode"],
  );

  Map<String, dynamic> toJson() => {
    "welcomeMessage": welcomeMessage,
    "numberOfTokens": numberOfTokens,
    "showClock": showClock,
    "messageAfterBusinessHours": messageAfterBusinessHours,
    "blurBackground": blurBackground,
    "enableServiceGroup": enableServiceGroup,
    "showBarcode": showBarcode,
  };
}

class Home {
  Home({
    this.name,
    this.enterpriseUrl,
    this.enterpriseApiKey,
    this.enterpriseApiSecret,
    this.enterpriseBranchId,
    this.id,
    this.version,
    this.address,
    this.rabbitMqUsername,
    this.rabbitMqpassword,
  });

  String name;
  String enterpriseUrl;
  String enterpriseApiKey;
  String enterpriseApiSecret;
  String enterpriseBranchId;
  String id;
  int version;
  Address address;
  String rabbitMqUsername;
  String rabbitMqpassword;

  factory Home.fromJson(Map<String, dynamic> json) => Home(
    name: json["name"],
    enterpriseUrl: json["enterpriseURL"],
    enterpriseApiKey: json["enterpriseApiKey"],
    enterpriseApiSecret: json["enterpriseApiSecret"],
    enterpriseBranchId: json["enterpriseBranchId"],
    id: json["id"],
    version: json["version"],
    address: Address.fromJson(json["address"]),
    rabbitMqUsername: json["rabbitMqUsername"],
    rabbitMqpassword: json["rabbitMqpassword"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "enterpriseURL": enterpriseUrl,
    "enterpriseApiKey": enterpriseApiKey,
    "enterpriseApiSecret": enterpriseApiSecret,
    "enterpriseBranchId": enterpriseBranchId,
    "id": id,
    "version": version,
    "address": address.toJson(),
    "rabbitMqUsername": rabbitMqUsername,
    "rabbitMqpassword": rabbitMqpassword,
  };
}

class Address {
  Address({
    this.id,
    this.created,
    this.createdBy,
    this.modified,
    this.lastModifiedBy,
    this.building,
    this.street,
    this.area,
    this.city,
    this.zip,
    this.country,
  });

  String id;
  DateTime created;
  String createdBy;
  DateTime modified;
  String lastModifiedBy;
  String building;
  String street;
  String area;
  String city;
  String zip;
  String country;

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json["id"],
    created: DateTime.parse(json["created"]),
    createdBy: json["createdBy"],
    modified: DateTime.parse(json["modified"]),
    lastModifiedBy: json["lastModifiedBy"],
    building: json["building"],
    street: json["street"],
    area: json["area"],
    city: json["city"],
    zip: json["zip"],
    country: json["country"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "created": created.toIso8601String(),
    "createdBy": createdBy,
    "modified": modified.toIso8601String(),
    "lastModifiedBy": lastModifiedBy,
    "building": building,
    "street": street,
    "area": area,
    "city": city,
    "zip": zip,
    "country": country,
  };
}

class Queue {
  Queue({
    this.strategy,
    this.slaWait,
    this.slaServe,
  });

  String strategy;
  int slaWait;
  int slaServe;

  factory Queue.fromJson(Map<String, dynamic> json) => Queue(
    strategy: json["strategy"],
    slaWait: json["slaWait"],
    slaServe: json["slaServe"],
  );

  Map<String, dynamic> toJson() => {
    "strategy": strategy,
    "slaWait": slaWait,
    "slaServe": slaServe,
  };
}

class Sms {
  Sms({
    this.id,
    this.version,
    this.enabled,
    this.updates,
    this.chooseMedium,
  });

  String id;
  int version;
  bool enabled;
  bool updates;
  bool chooseMedium;

  factory Sms.fromJson(Map<String, dynamic> json) => Sms(
    id: json["id"],
    version: json["version"],
    enabled: json["enabled"],
    updates: json["updates"],
    chooseMedium: json["chooseMedium"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "version": version,
    "enabled": enabled,
    "updates": updates,
    "chooseMedium": chooseMedium,
  };
}

class SurveyConf {
  SurveyConf({
    this.id,
    this.version,
    this.enabled,
    this.timeout,
    this.message,
    this.trigger,
  });

  String id;
  int version;
  bool enabled;
  int timeout;
  String message;
  String trigger;

  factory SurveyConf.fromJson(Map<String, dynamic> json) => SurveyConf(
    id: json["id"],
    version: json["version"],
    enabled: json["enabled"],
    timeout: json["timeout"],
    message: json["message"],
    trigger: json["trigger"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "version": version,
    "enabled": enabled,
    "timeout": timeout,
    "message": message,
    "trigger": trigger,
  };
}

class Theme {
  Theme({
    this.showTime,
    this.showArabic,
    this.showWaitingCustomers,
    this.showWaitingTime,
  });

  bool showTime;
  bool showArabic;
  bool showWaitingCustomers;
  bool showWaitingTime;

  factory Theme.fromJson(Map<String, dynamic> json) => Theme(
    showTime: json["showTime"],
    showArabic: json["showArabic"],
    showWaitingCustomers: json["showWaitingCustomers"],
    showWaitingTime: json["showWaitingTime"],
  );

  Map<String, dynamic> toJson() => {
    "showTime": showTime,
    "showArabic": showArabic,
    "showWaitingCustomers": showWaitingCustomers,
    "showWaitingTime": showWaitingTime,
  };
}

class Token {
  Token({
    this.tokenValidity,
  });

  int tokenValidity;

  factory Token.fromJson(Map<String, dynamic> json) => Token(
    tokenValidity: json["tokenValidity"],
  );

  Map<String, dynamic> toJson() => {
    "tokenValidity": tokenValidity,
  };
}

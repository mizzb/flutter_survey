// To parse this JSON data, do
//
//     final survey = surveyFromJson(jsonString);

import 'dart:convert';

Survey surveyFromJson(String str) => Survey.fromJson(json.decode(str));

String surveyToJson(Survey data) => json.encode(data.toJson());

class Survey {
  Survey({
    this.id,
    this.version,
    this.title,
    this.titles,
    this.messages,
  });

  String id;
  int version;
  String title;
  Messages titles;
  Messages messages;

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
    id: json["id"],
    version: json["version"],
    title: json["title"],
    titles: Messages.fromJson(json["titles"]),
    messages: Messages.fromJson(json["messages"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "version": version,
    "title": title,
    "titles": titles.toJson(),
    "messages": messages.toJson(),
  };
}

class Messages {
  Messages();

  factory Messages.fromJson(Map<String, dynamic> json) => Messages(
  );

  Map<String, dynamic> toJson() => {
  };
}



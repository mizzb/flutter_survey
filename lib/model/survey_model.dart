// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

Survey welcomeFromJson(String str) => Survey.fromJson(json.decode(str));

String welcomeToJson(Survey data) => json.encode(data.toJson());

class Survey {
  Survey({
    this.id,
    this.created,
    this.createdBy,
    this.modified,
    this.lastModifiedBy,
    this.title,
    this.goNextPageAutomatic,
    this.showQuestionNumbers,
    this.questionTitleTemplate,
    this.pages,
    this.titles,
    this.messages,
    this.template,
    this.projectId,
    this.links,
  });

  String id;
  DateTime created;
  dynamic createdBy;
  DateTime modified;
  dynamic lastModifiedBy;
  String title;
  bool goNextPageAutomatic;
  dynamic showQuestionNumbers;
  dynamic questionTitleTemplate;
  List<Page> pages;
  Messages titles;
  Messages messages;
  bool template;
  dynamic projectId;
  Links links;

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
    id: json["id"],
    created: DateTime.parse(json["created"]),
    createdBy: json["createdBy"],
    modified: DateTime.parse(json["modified"]),
    lastModifiedBy: json["lastModifiedBy"],
    title: json["title"],
    goNextPageAutomatic: json["goNextPageAutomatic"],
    showQuestionNumbers: json["showQuestionNumbers"],
    questionTitleTemplate: json["questionTitleTemplate"],
    pages: List<Page>.from(json["pages"].map((x) => Page.fromJson(x))),
    titles: Messages.fromJson(json["titles"]),
    messages: Messages.fromJson(json["messages"]),
    template: json["template"],
    projectId: json["projectId"],
    links: Links.fromJson(json["_links"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "created": created.toIso8601String(),
    "createdBy": createdBy,
    "modified": modified.toIso8601String(),
    "lastModifiedBy": lastModifiedBy,
    "title": title,
    "goNextPageAutomatic": goNextPageAutomatic,
    "showQuestionNumbers": showQuestionNumbers,
    "questionTitleTemplate": questionTitleTemplate,
    "pages": List<dynamic>.from(pages.map((x) => x.toJson())),
    "titles": titles.toJson(),
    "messages": messages.toJson(),
    "template": template,
    "projectId": projectId,
    "_links": links.toJson(),
  };
}

class Links {
  Links({
    this.self,
    this.survey,
  });

  Self self;
  Self survey;

  factory Links.fromJson(Map<String, dynamic> json) => Links(
    self: Self.fromJson(json["self"]),
    survey: Self.fromJson(json["survey"]),
  );

  Map<String, dynamic> toJson() => {
    "self": self.toJson(),
    "survey": survey.toJson(),
  };
}

class Self {
  Self({
    this.href,
  });

  String href;

  factory Self.fromJson(Map<String, dynamic> json) => Self(
    href: json["href"],
  );

  Map<String, dynamic> toJson() => {
    "href": href,
  };
}

class Messages {
  Messages();

  factory Messages.fromJson(Map<String, dynamic> json) => Messages(
  );

  Map<String, dynamic> toJson() => {
  };
}

class Page {
  Page({
    this.name,
    this.elements,
    this.questionsOrder,
  });

  String name;
  List<Element> elements;
  String questionsOrder;

  factory Page.fromJson(Map<String, dynamic> json) => Page(
    name: json["name"],
    elements: List<Element>.from(json["elements"].map((x) => Element.fromJson(x))),
    questionsOrder: json["questionsOrder"] == null ? null : json["questionsOrder"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "elements": List<dynamic>.from(elements.map((x) => x.toJson())),
    "questionsOrder": questionsOrder == null ? null : questionsOrder,
  };
}

class Element {
  Element({
    this.type,
    this.name,
    this.title,
    this.description,
    this.choices,
    this.choicesByUrl,
    this.columns,
    this.rows,
  });

  String type;
  String name;
  String title;
  String description;
  List<dynamic> choices;
  ChoicesByUrl choicesByUrl;
  List<dynamic> columns;
  List<String> rows;

  factory Element.fromJson(Map<String, dynamic> json) => Element(
    type: json["type"],
    name: json["name"],
    title: json["title"] == null ? null : json["title"],
    description: json["description"] == null ? null : json["description"],
    choices: json["choices"] == null ? null : List<dynamic>.from(json["choices"].map((x) => x)),
    choicesByUrl: json["choicesByUrl"] == null ? null : ChoicesByUrl.fromJson(json["choicesByUrl"]),
    columns: json["columns"] == null ? null : List<dynamic>.from(json["columns"].map((x) => x)),
    rows: json["rows"] == null ? null : List<String>.from(json["rows"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "name": name,
    "title": title == null ? null : title,
    "description": description == null ? null : description,
    "choices": choices == null ? null : List<dynamic>.from(choices.map((x) => x)),
    "choicesByUrl": choicesByUrl == null ? null : choicesByUrl.toJson(),
    "columns": columns == null ? null : List<dynamic>.from(columns.map((x) => x)),
    "rows": rows == null ? null : List<dynamic>.from(rows.map((x) => x)),
  };
}

class ChoiceClass {
  ChoiceClass({
    this.value,
    this.imageLink,
  });

  String value;
  String imageLink;

  factory ChoiceClass.fromJson(Map<String, dynamic> json) => ChoiceClass(
    value: json["value"],
    imageLink: json["imageLink"],
  );

  Map<String, dynamic> toJson() => {
    "value": value,
    "imageLink": imageLink,
  };
}

enum ChoiceEnum { ITEM1, ITEM3, ITEM5, ITEM4, ITEM2 }

final choiceEnumValues = EnumValues({
  "item1": ChoiceEnum.ITEM1,
  "item2": ChoiceEnum.ITEM2,
  "item3": ChoiceEnum.ITEM3,
  "item4": ChoiceEnum.ITEM4,
  "item5": ChoiceEnum.ITEM5
});

class ChoicesByUrl {
  ChoicesByUrl({
    this.url,
    this.titleName,
  });

  String url;
  String titleName;

  factory ChoicesByUrl.fromJson(Map<String, dynamic> json) => ChoicesByUrl(
    url: json["url"],
    titleName: json["titleName"],
  );

  Map<String, dynamic> toJson() => {
    "url": url,
    "titleName": titleName,
  };
}

class ColumnClass {
  ColumnClass({
    this.name,
  });

  ColumnEnum name;

  factory ColumnClass.fromJson(Map<String, dynamic> json) => ColumnClass(
    name: columnEnumValues.map[json["name"]],
  );

  Map<String, dynamic> toJson() => {
    "name": columnEnumValues.reverse[name],
  };
}

enum ColumnEnum { COLUMN_1, COLUMN_2, COLUMN_3 }

final columnEnumValues = EnumValues({
  "Column 1": ColumnEnum.COLUMN_1,
  "Column 2": ColumnEnum.COLUMN_2,
  "Column 3": ColumnEnum.COLUMN_3
});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}

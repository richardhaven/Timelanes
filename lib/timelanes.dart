library timelanes;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as international; // this package has a TextDirection which interferes with material.dart

enum EventAlignment { earlyPartial, latePartial, bothPartial, full }

typedef TimeEventWidgetBuilder = Widget Function(TimeEvent event, double maximumHeight, double pixelsPerMinute, EventAlignment eventAlignment);

const _defaultDateLabelFormat = "d MMMM yyyy";
const _defaultDateLabelStyle = TextStyle();
const _defaultTimelineStyle = TextStyle();
const _defaultLaneTitleStyle = TextStyle();
const _dividerHeight = 4.0;

final List<String> _emptyLanes = List<String>.empty();

const double timelineHeight = 25;

class TimeEvent {
  late DateTime start;
  late DateTime? end;
  late int laneIndex;
  late int priority;
  late TimeEventWidgetBuilder? builder;
  late String title;
  late double offsetLeft;
  TextStyle? titleStyle;

  Widget? widget;

  TimeEvent({
    required this.start,
    this.end,
    required this.laneIndex,
    this.priority = 1,
    this.builder,
    required this.title,
    this.offsetLeft = 0,
  });
}

enum TimelaneTitlePosition { left, right, both }

class Timelanes extends StatelessWidget {
  late final List<String> lanesAbove;
  late final List<String> lanesBelow;
  late final DateTime earliestDate;
  late final DateTime latestDate;

  late final double? dateLabelOffset;
  late final String? dateLabelFormat;
  late final TextStyle dateLabelStyle;
  late final TextStyle timelineStyle;
  late final TextStyle laneTitleStyle;
  late final TimelaneTitlePosition laneTitlePosition;
  late final Axis laneTitleOrientation;
  late final bool showSwimlanes;
  late final TimeEventWidgetBuilder? fallbackEventBuilder;

  Timelanes(
      {super.key,
      required this.earliestDate,
      required this.latestDate,
      List<String>? lanesAbove,
      List<String>? lanesBelow,
      this.dateLabelOffset,
      this.dateLabelFormat = _defaultDateLabelFormat,
      this.dateLabelStyle = _defaultDateLabelStyle, // TODO
      this.timelineStyle = _defaultTimelineStyle, // TODO
      this.laneTitleStyle = _defaultLaneTitleStyle,
      this.laneTitlePosition = TimelaneTitlePosition.left,
      this.laneTitleOrientation = Axis.horizontal,
      this.showSwimlanes = true,
      this.fallbackEventBuilder,
      this.events}) {
    if (lanesAbove == null) {
      this.lanesAbove = _emptyLanes; // cannot be a default parameter value
    } else {
      this.lanesAbove = lanesAbove;
    }
    if (lanesBelow == null) {
      this.lanesBelow = _emptyLanes; // cannot be a default parameter value
    } else {
      this.lanesBelow = lanesBelow;
    }
  }

  late final List<TimeEvent>? events;

  int get laneCount {
    return this.lanesAbove.length + this.lanesBelow.length;
  }

  @override
  Widget build(BuildContext context) {
    Widget result = LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      if (this.laneCount == 0) {
        return buildTimeline(constraints.maxWidth);
      }
      double availableLanesHeight = constraints.maxHeight - timelineHeight;
      if (this.showSwimlanes) {
        availableLanesHeight -= (_dividerHeight * (this.laneCount + 1));
      }
      double heightPerLane = availableLanesHeight / this.laneCount;
      return buildTimelanes(context, constraints, heightPerLane, constraints.maxWidth);
    });
    return result;
  }

// TODO: make separate title Widget instead of placing a title Widget within a lane
  Widget buildTimelanes(BuildContext context, BoxConstraints constraints, double laneHeight, double laneWidth) {
    Size maxLanesAboveTitleSize = _maxTextSize(this.lanesAbove, this.laneTitleStyle);
    Size maxLanesBelowTitleSize = _maxTextSize(this.lanesBelow, this.laneTitleStyle);
    double maxLaneTitleWidth = max(maxLanesAboveTitleSize.width, maxLanesBelowTitleSize.width);

    double remainingLaneWidth = constraints.maxWidth - maxLaneTitleWidth;
    if (this.laneTitlePosition == TimelaneTitlePosition.both) {
      remainingLaneWidth = constraints.maxWidth - (maxLaneTitleWidth * 2);
    }

    createEventWidgets(this.events, remainingLaneWidth, maxLaneTitleWidth, laneHeight);

    List<Widget> rows = List<Widget>.empty(growable: true);

    for (int index = 0; index < lanesAbove.length; index++) {
      if (this.showSwimlanes) {
        rows.add(const Divider(height: _dividerHeight));
      }

      List<TimeEvent> laneEvents = eventsForLane(this.events, index);
      List<TimeEvent> sortedEvents = sortEventsPriorityDescending(laneEvents);

      Widget lane = buildLane(sortedEvents, lanesAbove[index], laneWidth, laneHeight);
      rows.add(lane);
    }

    rows.add(buildTimeline(laneWidth));
    if (this.showSwimlanes) {
      rows.add(const Divider(height: _dividerHeight));
    }

    for (int index = 0; index < lanesBelow.length; index++) {
      int laneIndex = index + lanesAbove.length;

      List<TimeEvent> laneEvents = eventsForLane(this.events, laneIndex);
      List<TimeEvent> sortedEvents = sortEventsPriorityDescending(laneEvents);

      Widget lane = buildLane(sortedEvents, lanesBelow[index], laneWidth, laneHeight);
      rows.add(lane);

      if (this.showSwimlanes) {
        rows.add(const Divider(height: _dividerHeight));
      }

      laneIndex++;
    }

    return Column(children: rows);
  }

  Widget buildLane(List<TimeEvent> events, String title, double laneWidth, laneHeight) {
    List<Widget> eventWidgets = List<Widget>.empty(growable: true);

    if (this.laneTitlePosition == TimelaneTitlePosition.left || this.laneTitlePosition == TimelaneTitlePosition.both) {
      Widget laneTitle = _buildLaneTitle(title, this.laneTitleOrientation, this.laneTitleStyle, laneHeight, laneWidth, TimelaneTitlePosition.left);
      eventWidgets.add(laneTitle);
    }

    for (var event in events) {
      if (event.widget != null) {
        eventWidgets.add(event.widget!);
      }
    }
    if (this.laneTitlePosition == TimelaneTitlePosition.right || this.laneTitlePosition == TimelaneTitlePosition.both) {
      Widget laneTitle = _buildLaneTitle(title, this.laneTitleOrientation, this.laneTitleStyle, laneHeight, laneWidth, TimelaneTitlePosition.right);
      eventWidgets.add(laneTitle);
    }

    Widget result = Container(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      width: laneWidth,
      height: laneHeight,
      clipBehavior: Clip.none,
      child: Stack(children: eventWidgets),
    );

    return result;
  }

  Widget _buildLaneTitle(String text, Axis orientation, TextStyle style, double laneHeight, double laneWidth, TimelaneTitlePosition alignment) {
    text = text.replaceAll("\\n", "\n");
    if (this.laneTitleOrientation == Axis.horizontal) {
      Size titleSize = _textSize(text, style, width: 500);
      double top = (laneHeight / 2) - (titleSize.height / 2);
      double left = 0;
      if (alignment == TimelaneTitlePosition.right) {
        left = laneWidth - (titleSize.width + 10);
      }
      return Positioned(
          left: left,
          top: top,
          child: SizedBox(
            width: titleSize.width + 4,
            child: Text(
              text,
              style: style,
              maxLines: 5,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ));
    } else {
      double titleWidth = min(laneHeight, 150);
      Size titleSize = _textSize(text, style, width: titleWidth);
      double top = (laneHeight / 2) - (titleSize.width / 2);
      double left = 0;
      if (alignment == TimelaneTitlePosition.right) {
        left = laneWidth - (titleSize.height + 10);
      }
      return Positioned(
          left: left,
          top: top,
          child: SizedBox(
            width: titleSize.height + 4,
            height: titleSize.width + 4,
            child: RotatedBox(
                quarterTurns: -1,
                child: Text(
                  text,
                  style: style,
                  maxLines: 5,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                )),
          ));
    }
  }

  Widget buildTimeline(double laneWidth) {
    Duration timelineDuration = this.latestDate.difference(this.earliestDate);

    String earliestDateText = formatDateTime(this.earliestDate, timelineDuration, this.dateLabelFormat);
    String latestDateText = formatDateTime(this.latestDate, timelineDuration, this.dateLabelFormat);

    Widget result = SizedBox(
      height: timelineHeight,
      child: Column(children: [
        //  TODO: intermediate ticks
        Divider(height: calculateTimelineHeight()),
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(earliestDateText),
            Text(latestDateText),
          ]),
        )
      ]),
    );

    return result;
  }

  double calculateTimelineHeight() {
    // TODO: based on timelineStyle
    return 5.0;
  }

  void createEventWidgets(List<TimeEvent>? events, double laneWidth, double left, double laneHeight) {
    Duration timelineDuration = this.latestDate.difference(this.earliestDate);
    double pixelsPerMinute = laneWidth / timelineDuration.inMinutes;
    events?.forEach((TimeEvent event) {
      if (event.laneIndex < 0 || event.laneIndex >= this.laneCount) {
        return;
      }
      if (event.start.isAfter(latestDate)) {
        return;
      }
      if (event.end == null && event.start.isBefore(earliestDate)) {
        return;
      }
      if (event.end != null && event.end!.isBefore(earliestDate)) {
        return;
      }

      EventAlignment eventAlignment;
      if ((event.end == null) || (!event.start.isBefore(earliestDate) && !event.end!.isAfter(latestDate))) {
        eventAlignment = EventAlignment.full;
      } else if (event.start.isBefore(earliestDate)) {
        if (event.start.isAfter(latestDate)) {
          eventAlignment = EventAlignment.bothPartial;
        } else {
          eventAlignment = EventAlignment.earlyPartial;
        }
      } else {
        eventAlignment = EventAlignment.latePartial;
      }

      Widget eventWidget;
      if (event.builder != null) {
        eventWidget = event.builder!(event, laneHeight, pixelsPerMinute, eventAlignment);
      } else if (this.fallbackEventBuilder != null) {
        eventWidget = this.fallbackEventBuilder!(event, laneHeight, pixelsPerMinute, eventAlignment);
      } else if (event.title != "") {
        eventWidget = Text(event.title);
      } else {
        return;
      }

      Duration eventOffset = event.start.difference(this.earliestDate);
      double eventOffsetRatio = eventOffset.inSeconds / timelineDuration.inSeconds;
      double eventLeft = left + event.offsetLeft + (laneWidth * eventOffsetRatio);

      event.widget = Positioned(left: eventLeft, child: eventWidget);
    });
  }

  List<TimeEvent> sortEventsPriorityDescending(List<TimeEvent> laneEvents) {
    laneEvents.sort((TimeEvent event2, event1) => event1.priority.compareTo(event2.priority));
    return laneEvents;
  }

  List<TimeEvent> eventsForLane(List<TimeEvent>? events, int laneIndex) {
    List<TimeEvent> result = List<TimeEvent>.empty(growable: true);

    events?.forEach((TimeEvent event) {
      if (event.laneIndex == laneIndex) {
        result.add(event);
      }
    });

    return result;
  }
}

Widget createTimePeriod(
    {required Color color,
    required double rowHeight,
    required DateTime start,
    required DateTime end,
    required double pixelsPerMinute,
    String? title,
    TextStyle? titleStyle,
    EventAlignment eventAlignment = EventAlignment.full}) {
  Duration duration = end.difference(start);
  double width = duration.inMinutes * pixelsPerMinute;
  if (title == null) {
    return SizedBox(width: width, height: rowHeight, child: ColoredBox(color: color));
  } else {
    Size titleSize = _textSize(title, titleStyle ?? const TextStyle());
    if (titleSize.width > width) {
      eventAlignment = EventAlignment.full;
    }
    MainAxisAlignment titleAlign = MainAxisAlignment.center;
    Widget? box = null;
    switch (eventAlignment) {
      case EventAlignment.full:
      case EventAlignment.bothPartial:
        box = ColoredBox(color: color, child: Center(child: Text(title, style: titleStyle)));
      case EventAlignment.earlyPartial:
        titleAlign = MainAxisAlignment.end;
      case EventAlignment.latePartial:
        titleAlign = MainAxisAlignment.start;
    }
    box ??= ColoredBox(
        color: color, child: Row(mainAxisAlignment: titleAlign, crossAxisAlignment: CrossAxisAlignment.center, children: [Text(title, style: titleStyle)]));

    return SizedBox(width: width, height: rowHeight, child: box);
  }
}

Size _textSize(String text, TextStyle style, {double width = double.infinity}) {
  final TextPainter textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(text: text, style: style),
  )..layout(minWidth: 0, maxWidth: width);
  return textPainter.size;
}

Size _maxTextSize(List<String>? texts, TextStyle style) {
  double width = 0;
  double height = 0;
  if (texts != null) {
    for (String text in texts) {
      Size size = _textSize(text, style);
      if (size.width > width) {
        width = size.width;
      }
      if (size.height > height) {
        height = size.height;
      }
    }
  }
  return Size(width, height);
}

String formatDateTime(DateTime dateTime, Duration scope, String? format) {
  if (format == null) {
    if (scope < const Duration(days: 1)) {
      format = "hh:mm";
    } else if (scope < const Duration(days: 365)) {
      format = "dd MMMM yy";
    } else if (scope < const Duration(days: 1500)) {
      format = "MMMM yyyy";
    } else {
      format = "yyyy";
    }
  }
  international.DateFormat dateFormatter = international.DateFormat(format);
  return dateFormatter.format(dateTime);
}

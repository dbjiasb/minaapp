import 'package:biz/base/crypt/routes.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';

import '../crypt/security.dart';

enum CountDownTimerFormat {
  daysHoursMinutesSeconds,
  daysHoursMinutes,
  daysHours,
  daysOnly,
  hoursMinutesSeconds,
  hoursMinutes,
  hoursOnly,
  minutesSeconds,
  minutesOnly,
  secondsOnly,
}

typedef OnTickCallBack = void Function(Duration remainingTime);

class TimerDownView extends StatefulWidget {
  /// Format for the timer coundtown, choose between different `CountDownTimerFormat`s
  final CountDownTimerFormat format;

  /// Defines the time when the timer is over.
  final DateTime endTime;

  /// Gives you remaining time after every tick.
  final OnTickCallBack? onTick;

  /// Function to call when the timer is over.
  final VoidCallback? onEnd;

  /// Toggle time units descriptions.
  final bool enableDescriptions;

  /// `TextStyle` for the time numbers.
  final TextStyle? timeTextStyle;

  /// `TextStyle` for the colons betwenn the time numbers.
  final TextStyle? colonsTextStyle;

  /// `TextStyle` for the description
  final TextStyle? descriptionTextStyle;

  /// Days unit description.
  String daysDescription = Security.security_days;

  /// Hours unit description.
  String hoursDescription = Security.security_hours;

  /// Minutes unit description.
  String minutesDescription = Security.security_minutes;

  /// Seconds unit description.
  String secondsDescription = Security.security_seconds;

  /// Defines the width between the colons and the units.
  double spacerWidth;

  TimerDownView({
    required this.endTime,
    this.format = CountDownTimerFormat.daysHoursMinutesSeconds,
    this.enableDescriptions = true,
    this.onEnd,
    this.timeTextStyle,
    this.onTick,
    this.colonsTextStyle,
    this.descriptionTextStyle,
    // this.daysDescription = Security.security_days,
    // this.hoursDescription = Security.security_hours,
    // this.minutesDescription = Security.security_minutes,
    // this.secondsDescription = Security.security_seconds,
    this.spacerWidth = 10,
  });

  @override
  _TimerCountdownState createState() => _TimerCountdownState();
}

class _TimerCountdownState extends State<TimerDownView> {
  Timer? timer;
  late String countdownDays;
  late String countdownHours;
  late String countdownMinutes;
  late String countdownSeconds;
  late Duration difference;

  @override
  void initState() {
    _startTimer();
    super.initState();
  }

  @override
  void dispose() {
    if (timer != null) {
      timer!.cancel();
    }
    super.dispose();
  }

  /// Calculate the time difference between now end the given [endTime] and initialize all UI timer values.
  ///
  /// Then create a periodic `Timer` which updates all fields every second depending on the time difference which is getting smaller.
  /// When this difference reached `Duration.zero` the `Timer` is stopped and the [onEnd] callback is invoked.
  void _startTimer() {
    if (widget.endTime.isBefore(DateTime.now())) {
      difference = Duration.zero;
    } else {
      difference = widget.endTime.difference(DateTime.now());
    }

    countdownDays = _durationToStringDays(difference);
    countdownHours = _durationToStringHours(difference);
    countdownMinutes = _durationToStringMinutes(difference);
    countdownSeconds = _durationToStringSeconds(difference);

    if (difference == Duration.zero) {
      if (widget.onEnd != null) {
        widget.onEnd!();
      }
    } else {
      timer = Timer.periodic(Duration(seconds: 1), (timer) {
        difference = widget.endTime.difference(DateTime.now());
        widget.onTick?.call(difference);
        setState(() {
          countdownDays = _durationToStringDays(difference);
          countdownHours = _durationToStringHours(difference);
          countdownMinutes = _durationToStringMinutes(difference);
          countdownSeconds = _durationToStringSeconds(difference);
        });
        if (difference <= Duration.zero) {
          timer.cancel();
          if (widget.onEnd != null) {
            widget.onEnd!();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _countDownTimerFormat();
  }

  /// Builds the UI colons between the time units.
  Widget _colon() {
    return Row(
      children: [
        SizedBox(width: widget.spacerWidth),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(":", style: widget.colonsTextStyle),
            if (widget.enableDescriptions) SizedBox(height: 5),
            if (widget.enableDescriptions) Text("", style: widget.descriptionTextStyle),
          ],
        ),
        SizedBox(width: widget.spacerWidth),
      ],
    );
  }

  /// Builds the timer days with its description.
  Widget _days(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(countdownDays, style: widget.timeTextStyle),
        if (widget.enableDescriptions) SizedBox(height: 5),
        if (widget.enableDescriptions) Text(widget.daysDescription, style: widget.descriptionTextStyle),
      ],
    );
  }

  /// Builds the timer hours with its description.
  Widget _hours(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(countdownHours, style: widget.timeTextStyle),
        if (widget.enableDescriptions) SizedBox(height: 5),
        if (widget.enableDescriptions) Text(widget.hoursDescription, style: widget.descriptionTextStyle),
      ],
    );
  }

  /// Builds the timer minutes with its description.
  Widget _minutes(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(countdownMinutes, style: widget.timeTextStyle),
        if (widget.enableDescriptions) SizedBox(height: 5),
        if (widget.enableDescriptions) Text(widget.minutesDescription, style: widget.descriptionTextStyle),
      ],
    );
  }

  /// Builds the timer seconds with its description.
  Widget _seconds(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(countdownSeconds, style: widget.timeTextStyle),
        if (widget.enableDescriptions) SizedBox(height: 5),
        if (widget.enableDescriptions) Text(widget.secondsDescription, style: widget.descriptionTextStyle),
      ],
    );
  }

  /// When the selected [CountDownTimerFormat] is leaving out the last unit, this function puts the UI value of the unit before up by one.
  ///
  /// This is done to show the currently running time unit.
  String _twoDigits(int n, String unitType) {
    if (unitType == Security.security_minutes) {
      if (widget.format == CountDownTimerFormat.daysHoursMinutes ||
          widget.format == CountDownTimerFormat.hoursMinutes ||
          widget.format == CountDownTimerFormat.minutesOnly) {
        if (difference > Duration.zero) {
          n++;
        }
      }
      if (n >= 10) return "$n";
      return "0$n";
    } else if (unitType == Security.security_hours) {
      if (widget.format == CountDownTimerFormat.daysHours || widget.format == CountDownTimerFormat.hoursOnly) {
        if (difference > Duration.zero) {
          n++;
        }
      }
      if (n >= 10) return "$n";
      return "0$n";
    } else if (unitType == Security.security_days) {
      if (widget.format == CountDownTimerFormat.daysOnly) {
        if (difference > Duration.zero) {
          n++;
        }
      }
      if (n >= 10) return "$n";
      return "0$n";
    } else {
      if (n >= 10) return "$n";
      return "0$n";
    }
  }

  /// Convert [Duration] in days to String for UI.
  String _durationToStringDays(Duration duration) {
    return _twoDigits(duration.inDays, Security.security_days).toString();
  }

  /// Convert [Duration] in hours to String for UI.
  String _durationToStringHours(Duration duration) {
    if (widget.format == CountDownTimerFormat.hoursMinutesSeconds ||
        widget.format == CountDownTimerFormat.hoursMinutes ||
        widget.format == CountDownTimerFormat.hoursOnly) {
      return _twoDigits(duration.inHours, Security.security_hours);
    } else
      return _twoDigits(duration.inHours.remainder(24), Security.security_hours).toString();
  }

  /// Convert [Duration] in minutes to String for UI.
  String _durationToStringMinutes(Duration duration) {
    if (widget.format == CountDownTimerFormat.minutesSeconds || widget.format == CountDownTimerFormat.minutesOnly) {
      return _twoDigits(duration.inMinutes, Security.security_minutes);
    } else
      return _twoDigits(duration.inMinutes.remainder(60), Security.security_minutes);
  }

  /// Convert [Duration] in seconds to String for UI.
  String _durationToStringSeconds(Duration duration) {
    if (widget.format == CountDownTimerFormat.secondsOnly) {
      return _twoDigits(duration.inSeconds, Security.security_seconds);
    } else
      return _twoDigits(duration.inSeconds.remainder(60), Security.security_seconds);
  }

  /// Switches the UI to be displayed based on [CountDownTimerFormat].
  Widget _countDownTimerFormat() {
    switch (widget.format) {
      case CountDownTimerFormat.daysHoursMinutesSeconds:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [_days(context), _colon(), _hours(context), _colon(), _minutes(context), _colon(), _seconds(context)],
        );
      case CountDownTimerFormat.daysHoursMinutes:
        return Row(mainAxisSize: MainAxisSize.min, children: [_days(context), _colon(), _hours(context), _colon(), _minutes(context)]);
      case CountDownTimerFormat.daysHours:
        return Row(mainAxisSize: MainAxisSize.min, children: [_days(context), _colon(), _hours(context)]);
      case CountDownTimerFormat.daysOnly:
        return Row(mainAxisSize: MainAxisSize.min, children: [_days(context)]);
      case CountDownTimerFormat.hoursMinutesSeconds:
        return Row(mainAxisSize: MainAxisSize.min, children: [_hours(context), _colon(), _minutes(context), _colon(), _seconds(context)]);
      case CountDownTimerFormat.hoursMinutes:
        return Row(mainAxisSize: MainAxisSize.min, children: [_hours(context), _colon(), _minutes(context)]);
      case CountDownTimerFormat.hoursOnly:
        return Row(mainAxisSize: MainAxisSize.min, children: [_hours(context)]);
      case CountDownTimerFormat.minutesSeconds:
        return Row(mainAxisSize: MainAxisSize.min, children: [_minutes(context), _colon(), _seconds(context)]);

      case CountDownTimerFormat.minutesOnly:
        return Row(mainAxisSize: MainAxisSize.min, children: [_minutes(context)]);
      case CountDownTimerFormat.secondsOnly:
        return Row(mainAxisSize: MainAxisSize.min, children: [_seconds(context)]);
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [_days(context), _colon(), _hours(context), _colon(), _minutes(context), _colon(), _seconds(context)],
        );
    }
  }
}

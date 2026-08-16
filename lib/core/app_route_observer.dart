import 'package:flutter/material.dart';

/// Lets pages stop transient work (such as media playback) when another route
/// covers them, while keeping the existing navigation structure unchanged.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

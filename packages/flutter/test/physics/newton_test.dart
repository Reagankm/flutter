// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('test_friction', () {
    FrictionSimulation friction = new FrictionSimulation(0.3, 100.0, 400.0);

    friction.tolerance = const Tolerance(velocity: 1.0);

    expect(friction.isDone(0.0), false);
    expect(friction.x(0.0), 100);
    expect(friction.dx(0.0), 400.0);

    expect(friction.x(1.0) > 330 && friction.x(1.0) < 335, true);

    expect(friction.dx(1.0), 120.0);
    expect(friction.dx(2.0), 36.0);
    expect(friction.dx(3.0), 10.8);
    expect(friction.dx(4.0) < 3.5, true);

    expect(friction.isDone(5.0), true);
    expect(friction.x(5.0) > 431 && friction.x(5.0) < 432, true);
  });

  test('test_friction_through', () {
    // Use a normal FrictionSimulation to generate start and end
    // velocity and positions with drag = 0.025.
    double startPosition = 10.0;
    double startVelocity = 600.0;
    FrictionSimulation f = new FrictionSimulation(0.025, startPosition, startVelocity);
    double endPosition = f.x(1.0);
    double endVelocity = f.dx(1.0);
    expect(endPosition, greaterThan(startPosition));
    expect(endVelocity, lessThan(startVelocity));

    // Verify that that the "through" FrictionSimulation ends up at
    // endPosition and endVelocity; implies that it computed the right
    // value for _drag.
    FrictionSimulation friction = new FrictionSimulation.through(
        startPosition, endPosition, startVelocity, endVelocity);
    expect(friction.isDone(0.0), false);
    expect(friction.x(0.0), 10.0);
    expect(friction.dx(0.0), 600.0);

    double epsilon = 1e-4;
    expect(friction.isDone(1.0 + epsilon), true);
    expect(friction.x(1.0), closeTo(endPosition, epsilon));
    expect(friction.dx(1.0), closeTo(endVelocity, epsilon));

    // Same scenario as above except that the velocities are
    // are negative.
    startPosition = 1000.0;
    startVelocity = -500.0;
    f = new FrictionSimulation(0.025, 1000.0, -500.0);
    endPosition = f.x(1.0);
    endVelocity = f.dx(1.0);
    expect(endPosition, lessThan(startPosition));
    expect(endVelocity, greaterThan(startVelocity));

    friction = new FrictionSimulation.through(
        startPosition, endPosition, startVelocity, endVelocity);
    expect(friction.isDone(1.0 + epsilon), true);
    expect(friction.x(1.0), closeTo(endPosition, epsilon));
    expect(friction.dx(1.0), closeTo(endVelocity, epsilon));
  });

  test('test_gravity', () {
    GravitySimulation gravity = new GravitySimulation(200.0, 100.0, 600.0, 0.0);

    expect(gravity.isDone(0.0), false);
    expect(gravity.x(0.0), 100.0);
    expect(gravity.dx(0.0), 0.0);

    // Starts at 100
    expect(gravity.x(0.25), 106.25);
    expect(gravity.x(0.50), 125);
    expect(gravity.x(0.75), 156.25);
    expect(gravity.x(1.00), 200);
    expect(gravity.x(1.25), 256.25);
    expect(gravity.x(1.50), 325);
    expect(gravity.x(1.75), 406.25);

    // Starts at 0.0
    expect(gravity.dx(0.25), 50.0);
    expect(gravity.dx(0.50), 100);
    expect(gravity.dx(0.75), 150.00);
    expect(gravity.dx(1.00), 200.0);
    expect(gravity.dx(1.25), 250.0);
    expect(gravity.dx(1.50), 300);
    expect(gravity.dx(1.75), 350);

    expect(gravity.isDone(2.5), true);
    expect(gravity.x(2.5), 725);
    expect(gravity.dx(2.5), 500.0);
  });

  test('spring_types', () {
    SpringSimulation crit = new SpringSimulation(new SpringDescription.withDampingRatio(
        mass: 1.0, springConstant: 100.0), 0.0, 300.0, 0.0);
    expect(crit.type, SpringType.criticallyDamped);

    crit = new SpringSimulation(new SpringDescription.withDampingRatio(
        mass: 1.0, springConstant: 100.0, ratio: 1.0), 0.0, 300.0, 0.0);
    expect(crit.type, SpringType.criticallyDamped);

    SpringSimulation under = new SpringSimulation(new SpringDescription.withDampingRatio(
        mass: 1.0, springConstant: 100.0, ratio: 0.75), 0.0, 300.0, 0.0);
    expect(under.type, SpringType.underDamped);

    SpringSimulation over = new SpringSimulation(new SpringDescription.withDampingRatio(
        mass: 1.0, springConstant: 100.0, ratio: 1.25), 0.0, 300.0, 0.0);
    expect(over.type, SpringType.overDamped);

    // Just so we don't forget how to create a desc without the ratio.
    SpringSimulation other = new SpringSimulation(
        const SpringDescription(mass: 1.0, springConstant: 100.0, damping: 20.0),
        0.0, 20.0, 20.0);
    expect(other.type, SpringType.criticallyDamped);
  });

  test('crit_spring', () {
    SpringSimulation crit = new SpringSimulation(new SpringDescription.withDampingRatio(
        mass: 1.0, springConstant: 100.0, ratio: 1.0), 0.0, 500.0, 0.0);

    crit.tolerance = const Tolerance(distance: 0.01, velocity: 0.01);

    expect(crit.type, SpringType.criticallyDamped);

    expect(crit.isDone(0.0), false);
    expect(crit.x(0.0), 0.0);
    expect(crit.dx(0.0), 5000.0);

    expect(crit.x(0.25).floor(), 458.0);
    expect(crit.x(0.50).floor(), 496.0);
    expect(crit.x(0.75).floor(), 499.0);

    expect(crit.dx(0.25).floor(), 410);
    expect(crit.dx(0.50).floor(), 33);
    expect(crit.dx(0.75).floor(), 2);

    expect(crit.isDone(1.50), true);
    expect(crit.x(1.5) > 499.0 && crit.x(1.5) < 501.0, true);
    expect(crit.dx(1.5) < 0.1, true /* basically within tolerance */);
  });

  test('overdamped_spring', () {
    SpringSimulation over = new SpringSimulation(new SpringDescription.withDampingRatio(
        mass: 1.0, springConstant: 100.0, ratio: 1.25), 0.0, 500.0, 0.0);

    over.tolerance = const Tolerance(distance: 0.01, velocity: 0.01);

    expect(over.type, SpringType.overDamped);

    expect(over.isDone(0.0), false);
    expect(over.x(0.0), 0.0);

    expect(over.x(0.5).floor(), 445.0);
    expect(over.x(1.0).floor(), 495.0);
    expect(over.x(1.5).floor(), 499.0);

    expect(over.dx(0.5).floor(), 273.0);
    expect(over.dx(1.0).floor(), 22.0);
    expect(over.dx(1.5).floor(), 1.0);

    expect(over.isDone(3.0), true);
  });

  test('underdamped_spring', () {
    SpringSimulation under = new SpringSimulation(new SpringDescription.withDampingRatio(
        mass: 1.0, springConstant: 100.0, ratio: 0.25), 0.0, 300.0, 0.0);
    expect(under.type, SpringType.underDamped);

    expect(under.isDone(0.0), false);

    // Overshot with negative velocity
    expect(under.x(1.0).floor(), 325);
    expect(under.dx(1.0).floor(), -65);

    expect(under.dx(6.0).floor(), 0.0);
    expect(under.x(6.0).floor(), 299);

    expect(under.isDone(6.0), true);
  });

  test('test_kinetic_scroll', () {
    SpringDescription spring = new SpringDescription.withDampingRatio(
        mass: 1.0, springConstant: 50.0, ratio: 0.5);

    ScrollSimulation scroll = new ScrollSimulation(
      position: 100.0,
      velocity: 800.0,
      leadingExtent: 0.0,
      trailingExtent: 300.0,
      spring: spring,
      drag: 0.3
    );
    scroll.tolerance = const Tolerance(velocity: 0.5, distance: 0.1);
    expect(scroll.isDone(0.0), false);
    expect(scroll.isDone(0.5), false); // switch from friction to spring
    expect(scroll.isDone(3.5), true);

    ScrollSimulation scroll2 = new ScrollSimulation(
      position: 100.0,
      velocity: -800.0,
      leadingExtent: 0.0,
      trailingExtent: 300.0,
      spring: spring,
      drag: 0.3
    );
    scroll2.tolerance = const Tolerance(velocity: 0.5, distance: 0.1);
    expect(scroll2.isDone(0.0), false);
    expect(scroll2.isDone(0.5), false); // switch from friction to spring
    expect(scroll2.isDone(3.5), true);
  });

  test('scroll_with_inf_edge_ends', () {
    SpringDescription spring = new SpringDescription.withDampingRatio(
        mass: 1.0, springConstant: 50.0, ratio: 0.5);

    ScrollSimulation scroll = new ScrollSimulation(
      position: 100.0,
      velocity: 400.0,
      leadingExtent: 0.0,
      trailingExtent: double.INFINITY,
      spring: spring,
      drag: 0.3,
    );
    scroll.tolerance = const Tolerance(velocity: 1.0);

    expect(scroll.isDone(0.0), false);
    expect(scroll.x(0.0), 100);
    expect(scroll.dx(0.0), 400.0);

    expect(scroll.x(1.0) > 330 && scroll.x(1.0) < 335, true);

    expect(scroll.dx(1.0), 120.0);
    expect(scroll.dx(2.0), 36.0);
    expect(scroll.dx(3.0), 10.8);
    expect(scroll.dx(4.0) < 3.5, true);

    expect(scroll.isDone(5.0), true);
    expect(scroll.x(5.0) > 431 && scroll.x(5.0) < 432, true);

    // We should never switch
    expect(scroll.currentIntervalOffset, 0.0);
  });

  test('over/under scroll spring', () {
    SpringDescription spring = new SpringDescription.withDampingRatio(mass: 1.0, springConstant: 170.0, ratio: 1.1);
    ScrollSimulation scroll = new ScrollSimulation(
      position: 500.0,
      velocity: -7500.0,
      leadingExtent: 0.0,
      trailingExtent: 1000.0,
      spring: spring,
      drag: 0.025,
    );
    scroll.tolerance = const Tolerance(velocity: 45.0, distance: 1.5);

    expect(scroll.isDone(0.0), false);
    expect(scroll.x(0.0), closeTo(500.0, .0001));
    expect(scroll.dx(0.0), closeTo(-7500.0, .0001));

    expect(scroll.isDone(0.025), false);
    expect(scroll.x(0.025), closeTo(320.0, 1.0));
    expect(scroll.dx(0.25), closeTo(-2982, 1.0));

    expect(scroll.isDone(2.0), true);
    expect(scroll.x(2.0), 0.0);
    expect(scroll.dx(2.0), closeTo(0.0, 45.0));
  });
}

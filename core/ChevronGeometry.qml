pragma Singleton

import QtQuick
import Quickshell

import qs

Singleton {
    enum Cap {
        Flat,
        Point,
        Notch
    }

    // Using chevronAngle in degrees, but converting to radians for calculations
    function calcCapWidth(height) {
        return (height / 2) / Math.tan(Math.PI * Settings.chevronAngle / 360);
    }

    // Six points at most: 1 (top-left corner) + 3 (right cap) + 2 (left cap)
    function polygon(width, height, leftCap, rightCap, leftCapProgress = 1, rightCapProgress = 1) {
        const capWidth = calcCapWidth(height);
        const leftWidth = capWidth * leftCapProgress;
        const rightWidth = capWidth * rightCapProgress;
        const mid = height / 2;
        const points = [];

        points.push(Qt.point(leftCap === ChevronGeometry.Cap.Point ? leftWidth : 0, 0));

        if (rightCap === ChevronGeometry.Cap.Point) {
            points.push(Qt.point(width - rightWidth, 0));
            points.push(Qt.point(width, mid));
            points.push(Qt.point(width - rightWidth, height));
        } else if (rightCap === ChevronGeometry.Cap.Notch) {
            points.push(Qt.point(width, 0));
            points.push(Qt.point(width - rightWidth, mid));
            points.push(Qt.point(width, height));
        } else {
            points.push(Qt.point(width, 0));
            points.push(Qt.point(width, height));
        }

        if (leftCap === ChevronGeometry.Cap.Point) {
            points.push(Qt.point(leftWidth, height));
            points.push(Qt.point(0, mid));
        } else if (leftCap === ChevronGeometry.Cap.Notch) {
            points.push(Qt.point(0, height));
            points.push(Qt.point(leftWidth, mid));
        } else {
            points.push(Qt.point(0, height));
        }

        points.push(points[0]);

        return points;
    }

    // Pointy and notch caps extend beyond the chevron's bounding box
    // Flat caps are flush with the chevron's bounding box
    function calcCapBoundingBox(height, cap, progress = 1) {
        if (cap === ChevronGeometry.Cap.Point || cap === ChevronGeometry.Cap.Notch)
            return calcCapWidth(height) * progress;

        return 0;
    }
}

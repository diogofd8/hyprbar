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
    function polygon(width, height, leftCap, rightCap) {
        const capWidth = calcCapWidth(height);
        const mid = height / 2;
        const points = [];

        points.push(Qt.point(leftCap === ChevronGeometry.Cap.Point ? capWidth : 0, 0));

        if (rightCap === ChevronGeometry.Cap.Point) {
            points.push(Qt.point(width - capWidth, 0));
            points.push(Qt.point(width, mid));
            points.push(Qt.point(width - capWidth, height));
        } else if (rightCap === ChevronGeometry.Cap.Notch) {
            points.push(Qt.point(width, 0));
            points.push(Qt.point(width - capWidth, mid));
            points.push(Qt.point(width, height));
        } else {
            points.push(Qt.point(width, 0));
            points.push(Qt.point(width, height));
        }

        if (leftCap === ChevronGeometry.Cap.Point) {
            points.push(Qt.point(capWidth, height));
            points.push(Qt.point(0, mid));
        } else if (leftCap === ChevronGeometry.Cap.Notch) {
            points.push(Qt.point(0, height));
            points.push(Qt.point(capWidth, mid));
        } else {
            points.push(Qt.point(0, height));
        }

        points.push(points[0]);

        return points;
    }

    // Pointy and notch caps extend beyond the chevron's bounding box
    // Flat caps are flush with the chevron's bounding box
    function calcCapBoundingBox(height, cap) {
        if (cap === ChevronGeometry.Cap.Point || cap === ChevronGeometry.Cap.Notch)
            return calcCapWidth(height);

        return 0;
    }

    // Content is offset by half the height for notch or pointy caps, but not for flat or pointy caps
    function calcContentOffset(height, cap) {
        if (cap === ChevronGeometry.Cap.Notch || cap === ChevronGeometry.Cap.Point)
            return calcCapWidth(height);

        return 0;
    }
}

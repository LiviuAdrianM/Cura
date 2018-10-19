// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.1
import QtGraphicalEffects 1.0
import UM 1.3 as UM

Item {
    id: root;
    property var printJob: null;
    property var running: isRunning(printJob);

    Button {
        id: button;
        background: Rectangle {
            color: UM.Theme.getColor("viewport_background"); // TODO: Theme!
            height: button.height;
            opacity: button.down || button.hovered ? 1 : 0;
            radius: 0.5 * width;
            width: button.width;
        }
        contentItem: Label {
            color: UM.Theme.getColor("monitor_context_menu_dots");
            font.pixelSize: 25 * screenScaleFactor;
            horizontalAlignment: Text.AlignHCenter;
            text: button.text;
            verticalAlignment: Text.AlignVCenter;
        }
        height: width;
        hoverEnabled: true;
        onClicked: parent.switchPopupState();
        text: "\u22EE"; //Unicode; Three stacked points.
        width: 35 * screenScaleFactor; // TODO: Theme!
    }

    Popup {
        id: popup;
        background: Item {
            height: popup.height;
            width: popup.width;

            DropShadow {
                anchors.fill: pointedRectangle;
                color: "#3F000000"; // 25% shadow
                radius: UM.Theme.getSize("monitor_shadow_radius").width;
                source: pointedRectangle;
                transparentBorder: true;
                verticalOffset: 2 * screenScaleFactor;
            }

            Item {
                id: pointedRectangle;
                anchors {
                    horizontalCenter: parent.horizontalCenter;
                    verticalCenter: parent.verticalCenter;
                }
                height: parent.height - 10 * screenScaleFactor; // Because of the shadow
                width: parent.width - 10 * screenScaleFactor; // Because of the shadow

                Rectangle {
                    id: point;
                    anchors {
                        right: bloop.right;
                        rightMargin: 24 * screenScaleFactor;
                    }
                    color: UM.Theme.getColor("monitor_context_menu_background");
                    height: 14 * screenScaleFactor;
                    transform: Rotation {
                        angle: 45;
                    }
                    width: 14 * screenScaleFactor;
                    y: 1 * screenScaleFactor;
                }

                Rectangle {
                    id: bloop;
                    anchors {
                        bottom: parent.bottom;
                        bottomMargin: 8 * screenScaleFactor; // Because of the shadow
                        top: parent.top;
                        topMargin: 8 * screenScaleFactor; // Because of the shadow + point
                    }
                    color: UM.Theme.getColor("monitor_context_menu_background");
                    width: parent.width;
                }
            }
        }
        clip: true;
        closePolicy: Popup.CloseOnPressOutside;
        contentItem: Column {
            id: popupOptions;
            anchors {
                top: parent.top;
                topMargin: UM.Theme.getSize("default_margin").height + 10 * screenScaleFactor; // Account for the point of the box
            }
            height: childrenRect.height + spacing * popupOptions.children.length + UM.Theme.getSize("default_margin").height;
            spacing: Math.floor(UM.Theme.getSize("default_margin").height / 2);
            width: parent.width;

            PrintJobContextMenuItem {
                enabled: {
                    if (printJob && !running) {
                        if (OutputDevice && OutputDevice.queuedPrintJobs[0]) {
                            return OutputDevice.queuedPrintJobs[0].key != printJob.key;
                        }
                    }
                    return false;
                }
                onClicked: {
                    sendToTopConfirmationDialog.visible = true;
                    popup.close();
                }
                text: catalog.i18nc("@label", "Move to top");
            }

            PrintJobContextMenuItem {
                enabled: printJob && !running;
                onClicked: {
                    deleteConfirmationDialog.visible = true;
                    popup.close();
                }
                text: catalog.i18nc("@label", "Delete");
            }

            PrintJobContextMenuItem {
                enabled: printJob && running;
                onClicked: {
                    if (printJob.state == "paused") {
                        printJob.setState("print");
                    } else if(printJob.state == "printing") {
                        printJob.setState("pause");
                    }
                    popup.close();
                }
                text: printJob && printJob.state == "paused" ? catalog.i18nc("@label", "Resume") : catalog.i18nc("@label", "Pause");
            }

            PrintJobContextMenuItem {
                enabled: printJob && running;
                onClicked: {
                    abortConfirmationDialog.visible = true;
                    popup.close();
                }
                text: catalog.i18nc("@label", "Abort");
            }
        }
        enter: Transition {
            NumberAnimation {
                duration: 75;
                property: "visible";
            }
        }
        exit: Transition {
            NumberAnimation {
                duration: 75;
                property: "visible";
            }
        }
        height: contentItem.height + 2 * padding;
        onClosed: visible = false;
        onOpened: visible = true;
        padding: UM.Theme.getSize("monitor_shadow_radius").width;
        transformOrigin: Popup.Top;
        visible: false;
        width: 182 * screenScaleFactor;
        x: (button.width - width) + 26 * screenScaleFactor;
        y: button.height + 5 * screenScaleFactor; // Because shadow
    }

    MessageDialog {
        id: sendToTopConfirmationDialog;
        Component.onCompleted: visible = false;
        icon: StandardIcon.Warning;
        onYes: OutputDevice.sendJobToTop(printJob.key);
        standardButtons: StandardButton.Yes | StandardButton.No;
        text: printJob && printJob.name ? catalog.i18nc("@label %1 is the name of a print job.", "Are you sure you want to move %1 to the top of the queue?").arg(printJob.name) : "";
        title: catalog.i18nc("@window:title", "Move print job to top");
    }

    MessageDialog {
        id: deleteConfirmationDialog;
        Component.onCompleted: visible = false;
        icon: StandardIcon.Warning;
        onYes: OutputDevice.deleteJobFromQueue(printJob.key);
        standardButtons: StandardButton.Yes | StandardButton.No;
        text: printJob && printJob.name ? catalog.i18nc("@label %1 is the name of a print job.", "Are you sure you want to delete %1?").arg(printJob.name) : "";
        title: catalog.i18nc("@window:title", "Delete print job");
    }

    MessageDialog {
        id: abortConfirmationDialog;
        Component.onCompleted: visible = false;
        icon: StandardIcon.Warning;
        onYes: printJob.setState("abort");
        standardButtons: StandardButton.Yes | StandardButton.No;
        text: printJob && printJob.name ? catalog.i18nc("@label %1 is the name of a print job.", "Are you sure you want to abort %1?").arg(printJob.name) : "";
        title: catalog.i18nc("@window:title", "Abort print");
    }

    // Utils
    function switchPopupState() {
        popup.visible ? popup.close() : popup.open();
    }
    function isRunning(job) {
        if (!job) {
            return false;
        }
        return ["paused", "printing", "pre_print"].indexOf(job.state) !== -1;
    }
}

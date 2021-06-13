import QtQuick 1.1
import "utils.js" as Utils

Tile {
	id: root

//// add to allow displaying remaining volume
    property VBusItem remainingItem: VBusItem { id: remainingItem; bind: Utils.path(bindPrefix, "/Remaining"); decimals: 0 }
    property VBusItem volumeUnit: VBusItem { bind: "com.victronenergy.settings/Settings/System/VolumeUnit" }
//// small tile height threshold
    property bool squeeze: height < 50

	property string bindPrefix: serviceName
	property string pumpBindPrefix
	property VBusItem levelItem: VBusItem { id: levelItem; bind: Utils.path(bindPrefix, "/Level"); decimals: 0; unit: "%" }
	property VBusItem fluidTypeItem: VBusItem { id: fluidTypeItem; bind: Utils.path(bindPrefix, "/FluidType") }
	property VBusItem customNameItem: VBusItem { id: customNameItem; bind: Utils.path(bindPrefix, "/CustomName") }
	property VBusItem pumpStateItem: VBusItem { id: pumpStateItem; bind: Utils.path(pumpBindPrefix, "/State") }
	property VBusItem pumpActiveService: VBusItem { id: pumpActiveService; bind: Utils.path(pumpBindPrefix, "/ActiveTankService") }
	property alias valueBarColor: valueBar.color
	property alias level: levelItem.value
	property int fullWarningLevel: ([2, 5].indexOf(fluidTypeItem.value) > -1) ? 80 : -1
	property int emptyWarningLevel: !([2, 5].indexOf(fluidTypeItem.value) > -1) ? 20 : -1
	property variant fluidTypes: [qsTr("Fuel"), qsTr("Fresh water"), qsTr("Waste water"), qsTr("Live well"), qsTr("Oil"), qsTr("Black water")]
	property variant fluidColor: ["#1abc9c", "#4aa3df", "#95a5a6", "#dcc6e0", "#f1a9a0", "#7f8c8d"]
	property bool blink: true
	property bool compact: false
	property string tankName: customNameItem.valid && customNameItem.value !== "" ? customNameItem.value : fluidTypeItem.valid ? fluidTypes[fluidTypeItem.value] : "TANK"

///// modified to keep mixed case names
    title: compact ? "" : tankName
	color: fluidTypeItem.valid ? fluidColor[fluidTypeItem.value] : "#4aa3df"

	Timer {
		interval: 1000
		running: pumpActiveService.value === bindPrefix && pumpStateItem.value === 1
		repeat: true
		onTriggered: blink = !blink
		onRunningChanged: if (!running) blink = true
	}

	function doScroll()
	{
		tankText.doScroll()
	}

	function warning()
	{
		if (fullWarningLevel != -1 && level >= fullWarningLevel)
			return true
		if (emptyWarningLevel != -1 && level <= emptyWarningLevel)
			return true
		return false
	}

	values: Item {
		width: root.width - 10
///// modified to keep mixed case names
        title: compact ? "" : tankName

		Marquee {
			id: tankText
//// modified to give bar more horizontal space
            width: Math.floor (parent.width * 0.3 )
			height: compact ? 13 : parent.height
			text: compact ? tankName : ""
			textHorizontalAlignment: Text.AlignLeft
			visible: compact
			scroll: false
			anchors {
//// modified to give move bar over title's line if space is tight
                verticalCenter: parent.verticalCenter; verticalCenterOffset: compact ? -9 : squeeze ? -4 : 0
			}
		}

		Rectangle {
			color: "#c0c0bd"
			border { width:1; color: "white" }
			width: root.width - 10 -  (compact ? tankText.width + 3 : 0)
			height: compact ? 13 : parent.height
			anchors {
//// modified to give move bar over title's line if space is tight
                verticalCenter: parent.verticalCenter; verticalCenterOffset: compact ? -9 : squeeze ? -4 : 0
				right: parent.right
			}

			Rectangle {
				id: valueBar
//// modified to always show a sliver of a bar even if tank is empty
                width: Math.max (root.level / 100 * parent.width - 2, 2)
				height: parent.height - 1
				color: warning() ? "#e74c3c" : "#34495e"
				opacity: blink ? 1 : 0.5
				anchors {
					verticalCenter: parent.verticalCenter;
					left: parent.left; leftMargin: 1
				}
			}

			Text {
				font.pixelSize: 12
				font.bold: true
//// include actual level in display
                text: root.levelItem.text + " " + TankSensor.formatVolume(volumeUnit.value, root.remainingItem.value)
				anchors.centerIn: parent
				color: "white"
			}
		}
	}
}

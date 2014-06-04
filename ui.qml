
import QtQuick 2.0
import QtQuick.Controls 1.1

ApplicationWindow {
    width: 525; height: 400
    visible: true

    ListView {
        id: mylist
        anchors.fill: parent
        clip: true

        model: list
        delegate: Text { text: modelData.text }
    }

    Button {
        anchors.bottom: parent.bottom
        text: "appendList"
        onClicked: { appendList("Appended"); }
    }
}

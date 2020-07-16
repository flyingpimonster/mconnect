/**
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * AUTHORS
 * Maciek Borzecki <maciek.borzecki (at] gmail.com>
 */

class BatteryHandler : Object, PacketHandlerInterface {
    public const string BATTERY = "kdeconnect.battery.request";
    public const string BATTERY_PKT = "kdeconnect.battery";

    public string get_pkt_type () {
        return BATTERY;
    }

    private uint lastLevel = UPowerDeviceProxy.WarningLevel.UNKNOWN;
    private UPowerDeviceProxy upower;
    private DBusPropertiesProxy upower_props;

    private BatteryHandler () {
        /* Get the "display device", which is the "main" battery */
        this.upower = Bus.get_proxy_sync (
            BusType.SYSTEM,
            "org.freedesktop.UPower",
            "/org/freedesktop/UPower/devices/DisplayDevice"
        );
        this.upower_props = Bus.get_proxy_sync (
            BusType.SYSTEM,
            "org.freedesktop.UPower",
            "/org/freedesktop/UPower/devices/DisplayDevice"
        );
        this.upower_props.properties_changed.connect (this.on_properties_changed);
    }

    public static BatteryHandler instance () {
        return new BatteryHandler ();
    }

    public void use_device (Device dev) {
        debug ("use device %s for battery status updates", dev.to_string ());
        dev.message.connect (this.message);
        local_update.connect (dev.send);
    }

    public void release_device (Device dev) {
        debug ("release device %s", dev.to_string ());
        dev.message.disconnect (this.message);
    }

    public void message (Device dev, Packet pkt) {
        if (pkt.pkt_type == BATTERY) {
            debug ("got battery request packet");

            dev.send (make_battery_packet ());
        } else if (pkt.pkt_type == BATTERY_PKT) {
            debug ("got battery packet");

            int64 level = pkt.body.get_int_member ("currentCharge");
            bool charging = pkt.body.get_boolean_member ("isCharging");

            debug ("battery level: %u %s", (uint) level,
                   (charging == true) ? "charging" : "");
            battery (dev, (uint) level, charging);
        }
    }

    public Packet make_battery_packet () {
        var state = upower.state;
        var level = upower.level;
        bool isCharging = state == UPowerDeviceProxy.State.CHARGING || state == UPowerDeviceProxy.State.FULLY_CHARGED;
        int currentCharge = (int) upower.percentage;
        bool enteredLowPower = (level == UPowerDeviceProxy.WarningLevel.LOW || level == UPowerDeviceProxy.WarningLevel.CRITICAL
                                && (this.lastLevel != UPowerDeviceProxy.WarningLevel.LOW && this.lastLevel != UPowerDeviceProxy.WarningLevel.CRITICAL));
        this.lastLevel = level;

        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("isCharging");
        builder.add_boolean_value (isCharging);
        builder.set_member_name ("currentCharge");
        builder.add_int_value (currentCharge);
        if (enteredLowPower) {
            builder.set_member_name ("thresholdEvent");
            builder.add_int_value (1);
        }
        builder.end_object ();
        return new Packet (BATTERY_PKT, builder.get_root ().get_object ());
    }

    public void on_properties_changed (string interface_name, HashTable<string, Variant> changed) {
        // make sure we only respond to device properties
        if (interface_name == "org.freedesktop.UPower.Device") {
            // and only these specific properties, ignore the rest
            if ("Percentage" in changed || "State" in changed || "WarningLevel" in changed) {
                // send out an update
                this.local_update (this.make_battery_packet ());
            }
        }
    }

    public signal void battery (Device dev, uint level, bool charging);

    public signal void local_update (Packet pkt);
}

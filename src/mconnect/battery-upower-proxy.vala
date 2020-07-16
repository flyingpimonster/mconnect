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
 * James Westman <james@flyingpimonster.net>
 */

/**
 * The org.freedesktop.UPower.Device DBus API. See
 * https://upower.freedesktop.org/docs/Device.html
 */
[DBus (name = "org.freedesktop.UPower.Device")]
interface UPowerDeviceProxy : Object {
    public enum State {
        UNKNOWN = 0,
        CHARGING = 1,
        DISCHARDING = 2,
        EMPTY = 3,
        FULLY_CHARGED = 4,
        PENDING_CHARGE = 5,
        PENDING_DISCHARGE = 6,
    }

    public enum WarningLevel {
        UNKNOWN = 0,
        NONE = 1,
        DISCHARGING = 2,
        LOW = 3,
        CRITICAL = 4,

    }

    public abstract double percentage { get; }
    public abstract uint state { get; }
    public abstract uint level { get; }
}

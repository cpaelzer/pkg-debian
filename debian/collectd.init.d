#!/bin/bash
#
# collectd - start and stop the statistics collection daemon
# http://collectd.org/
#
# Copyright (C) 2005-2006 Florian Forster <octo@verplant.org>
# Copyright (C) 2006-2007 Sebastian Harl <sh@tokkee.org>
#

### BEGIN INIT INFO
# Provides:          collectd
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Should-Start:      $network $named $syslog $time
# Should-Stop:       $network $named $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: start the statistics collection daemon
### END INIT INFO

set -e

PATH=/sbin:/bin:/usr/sbin:/usr/bin

DISABLE=0

DESC="statistics collection daemon"
NAME=collectd
DAEMON=/usr/sbin/collectd

CONFIGFILE=/etc/collectd/collectd.conf
PIDFILE=/var/run/collectd.pid

MAXWAIT=30

# Gracefully exit if the package has been removed.
test -x $DAEMON || exit 0

if [ -r /etc/default/$NAME ]; then
	. /etc/default/$NAME
fi

if test "$DISABLE" != 0; then
	echo "$NAME has been disabled - see /etc/default/$NAME."
	exit 0
fi

d_start() {
	start-stop-daemon --start --quiet --pidfile "$PIDFILE" \
		--exec $DAEMON -- -C "$CONFIGFILE" -P "$PIDFILE"
}

still_running_warning="
WARNING: $NAME might still be running.
In large setups it might take some time to write all pending data to
the disk. You can adjust the waiting time in /etc/default/collectd."

d_stop() {
	PID=$( cat "$PIDFILE" 2> /dev/null ) || true

	start-stop-daemon --stop --quiet --oknodo --pidfile "$PIDFILE"

	sleep 1
	if test -n "$PID" && kill -0 $PID 2> /dev/null; then
		i=0
		while kill -0 $PID 2> /dev/null; do
			i=$(( $i + 2 ))
			echo -n " ."

			if test $i -gt $MAXWAIT; then
				echo "$still_running_warning"
				return 1
			fi

			sleep 2
		done
		return 0
	fi
}

case "$1" in
	start)
		echo -n "Starting $DESC: $NAME"
		d_start
		echo "."
		;;
	stop)
		echo -n "Stopping $DESC: $NAME"
		d_stop
		echo "."
		;;
	restart|force-reload)
		echo -n "Restarting $DESC: $NAME"
		d_stop
		sleep 1
		d_start
		echo "."
		;;
	*)
		echo "Usage: $0 {start|stop|restart|force-reload}" >&2
		exit 1
		;;
esac

exit 0

# vim: syntax=sh noexpandtab sw=4 ts=4 :


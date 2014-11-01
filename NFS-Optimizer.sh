EXPORT="192.168.10.131:/export/Torrent"
MNTDIR="/mnt/Torrent"
TESTFILE="movie.mp4"

NFSPROTO="udp"
if [[ -n "$1" ]]; then
NFSPROTO="tcp"
fi

echo "Testing transfer speed of $NFSPROTO on file $EXPORT/$TESTFILE"
echo

for rsize in 8192 16384 32768 65536 4294967296
do
if mount | grep $MNTDIR > /dev/null; then
  sudo umount $MNTDIR
fi

sudo mount -t nfs -o rsize=$rsize,$NFSPROTO,cto,noatime,intr,nfsvers=3 $EXPORT $MNTDIR

mntedrsize=$(cat /proc/mounts | grep $MNTDIR | grep -oE "rsize=[0-9]{4,6}" | grep -oE "[0-9]{4,6}")

echo $MNTDIR mounted @ rsize \($((mntedrsize/1024))K\), requested rsize \($((rsize/1024))K\)

sudo dd if=$MNTDIR/$TESTFILE of=/dev/null | grep "copied"

echo
done

sudo umount $MNTDIR
package disk

import (
	"time"

	boshlog "github.com/cloudfoundry/bosh-agent/logger"
	boshsys "github.com/cloudfoundry/bosh-agent/system"
)

type linuxDiskManager struct {
	partitioner           Partitioner
	rootDevicePartitioner RootDevicePartitioner
	formatter             Formatter
	mounter               Mounter
	mountsSearcher        MountsSearcher
}

func NewLinuxDiskManager(
	logger boshlog.Logger,
	runner boshsys.CmdRunner,
	fs boshsys.FileSystem,
	bindMount bool,
) (manager Manager) {
	var mounter Mounter
	var mountsSearcher MountsSearcher

	// By default we want to use most reliable source of
	// mount information which is /proc/mounts
	mountsSearcher = NewProcMountsSearcher(fs)

	// Bind mounting in a container (warden) will not allow
	// reliably determine which device backs a mount point,
	// so we use less reliable source of mount information:
	// the mount command which returns information from /etc/mtab.
	if bindMount {
		mountsSearcher = NewCmdMountsSearcher(runner)
	}

	mounter = NewLinuxMounter(runner, mountsSearcher, 1*time.Second)

	if bindMount {
		mounter = NewLinuxBindMounter(mounter)
	}

	return linuxDiskManager{
		partitioner:           NewSfdiskPartitioner(logger, runner),
		rootDevicePartitioner: NewPartedPartitioner(logger, runner),
		formatter:             NewLinuxFormatter(runner, fs),
		mounter:               mounter,
		mountsSearcher:        mountsSearcher,
	}
}

func (m linuxDiskManager) GetPartitioner() Partitioner { return m.partitioner }

func (m linuxDiskManager) GetRootDevicePartitioner() RootDevicePartitioner {
	return m.rootDevicePartitioner
}

func (m linuxDiskManager) GetFormatter() Formatter           { return m.formatter }
func (m linuxDiskManager) GetMounter() Mounter               { return m.mounter }
func (m linuxDiskManager) GetMountsSearcher() MountsSearcher { return m.mountsSearcher }
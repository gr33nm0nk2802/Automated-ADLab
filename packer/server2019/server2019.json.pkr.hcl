
packer {
  required_version = ">= 1.8.5"
  required_plugins {
    vmware = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

variable "autounattend" {
  type    = string
  default = "file/answer_file/Autounattend.xml"
}

variable "disk_size" {
  type    = string
  default = "61440"
}

variable "disk_type_id" {
  type    = string
  default = "0"
}

variable "headless" {
  type    = string
  default = "false"
}

variable "hyperv_switchname" {
  type    = string
  default = "${env("hyperv_switchname")}"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:549bca46c055157291be6c22a3aaaed8330e78ef4382c99ee82c896426a1cee1"
}

variable "iso_url" {
  type    = string
  default = "../../iso_files/server2019/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
}

variable "manually_download_iso_from" {
  type    = string
  default = "./iso/"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "restart_timeout" {
  type    = string
  default = "5m"
}

variable "vm_name" {
  type = string
  default = "win-server2019"
}

variable "vmx_version" {
  type    = string
  default = "16"
}

variable "winrm_timeout" {
  type    = string
  default = "2h"
}

source "virtualbox-iso" "server-2019" {
  boot_wait            = "2m"
  communicator         = "winrm"
  cpus                 = 2
  disk_size            = "${var.disk_size}"
  floppy_files         = ["${var.autounattend}", "file/disable-screensaver.ps1", "file/enable-winrm.ps1", "file/unattend.xml", "file/sysprep.bat"]
  guest_additions_mode = "disable"
  guest_os_type        = "Windows2016_64"
  headless             = "${var.headless}"
  iso_checksum         = "${var.iso_checksum}"
  iso_url              = "${var.iso_url}"
  memory               = "${var.memory}"
  shutdown_command     = "a:/sysprep.bat"
  vm_name              = "${var.vm_name}"
  winrm_password       = "vagrant"
  winrm_timeout        = "${var.winrm_timeout}"
  winrm_username       = "vagrant"
}

source "vmware-iso" "server-2019" {
  boot_wait         = "2m"
  communicator      = "winrm"
  cpus              = 2
  disk_adapter_type = "lsisas1068"
  disk_size         = "${var.disk_size}"
  disk_type_id      = "${var.disk_type_id}"
  floppy_files         = ["${var.autounattend}", "file/disable-screensaver.ps1", "file/enable-winrm.ps1", "file/unattend.xml", "file/sysprep.bat"]
  guest_os_type     = "windows9srv-64"
  headless          = "${var.headless}"
  iso_checksum      = "${var.iso_checksum}"
  iso_url           = "${var.iso_url}"
  memory            = "${var.memory}"
  shutdown_command  = "a:/sysprep.bat"
  version           = "${var.vmx_version}"
  vm_name           = "${var.vm_name}"
  vmx_data = {
    "RemoteDisplay.vnc.enabled" = "false"
    "RemoteDisplay.vnc.port"    = "5900"
  }
  vmx_remove_ethernet_interfaces = true
  vnc_port_max                   = 5980
  vnc_port_min                   = 5900
  winrm_password                 = "vagrant"
  winrm_timeout                  = "${var.winrm_timeout}"
  winrm_username                 = "vagrant"
}

build {
  sources = ["source.virtualbox-iso.server-2019", "source.vmware-iso.server-2019"]

  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c \"{{ .Path }}\""
    scripts         = ["file/enable-rdp.bat"]
  }

  provisioner "powershell" {
    scripts = ["file/vm-guest-tools.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "${var.restart_timeout}"
  }

  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c \"{{ .Path }}\""
    scripts         = ["file/pin-powershell.bat", "file/set-winrm-automatic.bat", "file/uac-enable.bat", "file/disable-updates.bat"]
  }

  post-processor "vagrant" {
    keep_input_artifact  = false
    output               = "../../vagrant/server2019/server2019_{{ .Provider }}.box"
    vagrantfile_template = "vagrantfile-windows_2019.template"
  }
}

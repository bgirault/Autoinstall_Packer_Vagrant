packer {
  required_plugins {
    vmware = {
      source  = "github.com/hashicorp/vmware"
      version = "~> 1"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

source "vmware-iso" "WS2022" {
  // Nom de la VM et système invité (Windows Server 2022)
  vm_name = "WS2022" 
  guest_os_type = "windows2019srvnext-64"
  version = "21"
  
  // ISO source pour l'installation et checksum (Get-FileHash)
  //iso_url = "F:/ISOS/W2K22_eval.iso"
  //iso_checksum = "md5:9f3adfcc5b9f88bd38fe28a7b5f873a6"
  iso_url = "F:/ISOS/SERVER_EVAL_x64FRE_fr-fr.iso"
  iso_checksum = "md5:7d868f68544c26fbfba7e0d52d45ba1c"

  // Config de la VM : CPU, RAM, disque, réseau
  cpus = "2"
  cores = "1"
  memory = "4096"
  disk_adapter_type = "nvme"
  disk_size = "50000"
  disk_additional_size = [
    10000
  ]

  network_adapter_type = "e1000e"
  // Commande pour enlever les cartes réseaux
  vmx_remove_ethernet_interfaces = true
  
  // Connexion WINRM
  communicator = "winrm"
  winrm_port = "5985"
  insecure_connection = "true"
  winrm_username = "Administrateur"
  winrm_password = "P@ssword!"
  
  // Lecteur disquette (charger autounantend.xml et les scripts)
  floppy_files = ["${path.root}/setup/"]
  floppy_label = "floppy"

  // Commande pour arrêter le système  
  // shutdown_command = "shutdown /s /t 30 /f"
  shutdown_command = "C:\\Windows\\system32\\Sysprep\\sysprep.exe /generalize /oobe /shutdown /unattend:a:\\sysprep-autounattend.xml"
  shutdown_timeout = "60m"
}

build {
  sources = ["sources.vmware-iso.WS2022"]

  // Installer PowerShell (dernière version disponible sur GitHub)
  provisioner "powershell" {
    script = "${path.root}/setup/install-powershell.ps1"
  }  
  
  // Installer VMware Tools
  provisioner "powershell" {
    script = "${path.root}/setup/install-vmtools.ps1"
  }  
  
  // Initier un redémarrage de la machine
  provisioner "windows-restart" {
    restart_timeout = "10m"
  }
 
  // Export sous la forme d'une box Vagrant
  post-processor "vagrant" {
	keep_input_artifact = false
	output = "packer_{{.BuildName}}_{{.Provider}}.box"
    provider_override = "vmware"
  }
}
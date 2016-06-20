define windows_xmltask($taskname = $title, $xmlfile, $overwrite = false, $ensure = 'present') {
  if ! ($ensure in [ 'present', 'absent' ]) {
    fail('valid values for ensure are \'present\' or \'absent\'')
  }
  $null  = '$null'
  $false = '$false'
  $temp_filename = fqdn_rand(3000, $taskname)
  if ($ensure == 'present') {
    if ($overwrite == true){
      $is_force = '-Force'
    }
    notify {"command = if( ((Get-ScheduledTask 'sync-gcloud-tools-share-v1') -eq ${null}) -Or ('${overwrite}' -eq 'true')){ exit 0 }else{ exit 1 }":}
    file {"c:\\Users\\Public\\${temp_filename}.xml":
      ensure             => file,
      source_permissions => 'ignore',
      source             => $xmlfile,
    } ->
    exec { "Importing task ${taskname}":
      command  => "
        Try{
          Register-ScheduledTask -Xml (get-content 'C:\Users\Public\${temp_filename}.xml' | out-string) -TaskName '${taskname}' ${is_force}
          Remove-Item 'c:\Users\Public\${temp_filename}.xml'
        }
        Catch{
          exit 0
        }
      ",
      provider => powershell,
      onlyif   => "if( ((Get-ScheduledTask 'sync-gcloud-tools-share-v1') -eq ${null}) -Or ('${overwrite}' -eq 'true')){ exit 0 }else{ exit 1 }",
      require  => File['c:\\Users\\Public\\${temp_filename}.xml'],
    }
  }else{
    exec { "Removing task ${taskname}":
      command  => "Unregister-ScheduledTask -TaskName '${taskname}' -Confirm:${false}",
      provider => powershell,
      onlyif   => "Get-ScheduledTask '${taskname}'",
    }
  }
}
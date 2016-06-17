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
    notify {"\$overwrite = ${overwrite}":}
    notify {"command = if ('${overwrite}' -eq '${false}') {exit 1}":}
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
      unless   => [
                    "Get-ScheduledTask '${taskname}'",
                    "if ('${overwrite}' -eq '${false}') {exit 1}",
                  ]
    }
  }else{
    exec { "Removing task ${taskname}":
      command  => "Unregister-ScheduledTask -TaskName '${taskname}' -Confirm:${false}",
      provider => powershell,
      onlyif   => "Get-ScheduledTask '${taskname}'",
    }
  }
}
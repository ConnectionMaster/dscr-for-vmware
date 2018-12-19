<#
Copyright (c) 2018 VMware, Inc.  All rights reserved

The BSD-2 license (the "License") set forth below applies to all parts of the Desired State Configuration Resources for VMware project.  You may not use this file except in compliance with the License.

BSD-2 License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>

[DscResource()]
class VMHostSettings : VMHostBaseDSC {
    <#
    .DESCRIPTION

    Motd value.
    #>
    [DscProperty()]
    [string] $Motd

    <#
    .DESCRIPTION

    Clear the Motd content
    #>
    [DscProperty()]
    [bool] $MotdClear

    <#
    .DESCRIPTION

    Issue value.
    #>
    [DscProperty()]
    [string] $Issue

    <#
    .DESCRIPTION

    Clear the Issue content
    #>
    [DscProperty()]
    [bool] $IssueClear

    hidden [string] $IssueSettingName = "Config.Etc.issue"
    hidden [string] $MotdSettingName = "Config.Etc.motd"

    [void] Set() {
    	Write-Verbose -Message "$(Get-Date) $($s = Get-PSCallStack; "Entering {0}" -f $s[0].FunctionName)"

    	$this.ConnectVIServer()
    	$vmHost = $this.GetVMHost()

        $this.UpdateVMHostSettings($vmHost)
    }

    [bool] Test() {
    	Write-Verbose -Message "$(Get-Date) $($s = Get-PSCallStack; "Entering {0}" -f $s[0].FunctionName)"

    	$this.ConnectVIServer()
    	$vmHost = $this.GetVMHost()

        return !$this.ShouldUpdateVMHostSettings($vmHost)
    }

    [VMHostSettings] Get() {
    	Write-Verbose -Message "$(Get-Date) $($s = Get-PSCallStack; "Entering {0}" -f $s[0].FunctionName)"

    	$result = [VMHostSettings]::new()

    	$this.ConnectVIServer()
    	$vmHost = $this.GetVMHost()
    	$this.PopulateResult($vmHost, $result)

        return $result
    }

    <#
    .DESCRIPTION

    Returns a boolean value indicating if the Advanced Setting value should be updated.
    #>
    [bool] ShouldUpdateSettingValue($desiredValue, $currentValue) {
    	<#
        Desired value equal to $null means that the setting value was not specified.
        If it is specified we check if the setting value is not equal to the current value.
        #>
    	Write-Verbose -Message "$(Get-Date) $($s = Get-PSCallStack; "Entering {0}" -f $s[0].FunctionName)"

        return ($null -ne $desiredValue -and $desiredValue -ne $currentValue)
    }

    <#
    .DESCRIPTION

    Returns a boolean value indicating if at least one Advanced Setting value should be updated.
    #>
    [bool] ShouldUpdateVMHostSettings($VMHost) {
    	Write-Verbose -Message "$(Get-Date) $($s = Get-PSCallStack; "Entering {0}" -f $s[0].FunctionName)"

    	$VMHostCurrentAdvancedSettings = Get-AdvancedSetting -Server $this.Connection -Entity $VMHost

    	$currentMotd = $VMHostCurrentAdvancedSettings | Where-Object { $_.Name -eq $this.MotdSettingName }
    	$currentIssue = $VMHostCurrentAdvancedSettings | Where-Object { $_.Name -eq $this.IssueSettingName }

    	$shouldUpdateVMHostSettings = @()
    	$shouldUpdateVMHostSettings += ($this.MotdClear -and ($currentMotd.Value -ne [string]::Empty)) -or (-not $this.MotdClear -and ($this.Motd -ne $currentMotd.Value))
    	$shouldUpdateVMHostSettings += ($this.IssueClear -and ($currentIssue.Value -ne [string]::Empty)) -or (-not $this.IssueClear -and ($this.Issue -ne $currentIssue.Value))

        return ($shouldUpdateVMHostSettings -Contains $true)
    }

  	<#
    .DESCRIPTION

    Sets the desired value for the Advanced Setting, if update of the Advanced Setting value is needed.
    #>
  	[void] SetAdvancedSetting($advancedSetting, $advancedSettingDesiredValue, $advancedSettingCurrentValue, $clearValue) {
    	Write-Verbose -Message "$(Get-Date) $($s = Get-PSCallStack; "Entering {0}" -f $s[0].FunctionName)"

    	if ($clearValue) {
      	    if ($this.ShouldUpdateSettingValue([string]::Empty, $advancedSettingCurrentValue)) {
                  Set-AdvancedSetting -AdvancedSetting $advancedSetting -Value [string]::Empty -Confirm:$false
      	    }
    	}
    	else {
      	    if ($this.ShouldUpdateSettingValue($advancedSettingDesiredValue, $advancedSettingCurrentValue)) {
                  Set-AdvancedSetting -AdvancedSetting $advancedSetting -Value $advancedSettingDesiredValue -Confirm:$false
      	    }
    	}
    }

    <#
    .DESCRIPTION

    Performs update on those Advanced Settings values that needs to be updated.
    #>
    [void] UpdateVMHostSettings($VMHost) {
    	Write-Verbose -Message "$(Get-Date) $($s = Get-PSCallStack; "Entering {0}" -f $s[0].FunctionName)"

    	$VMHostCurrentAdvancedSettings = Get-AdvancedSetting -Server $this.Connection -Entity $VMHost

    	$currentMotd = $VMHostCurrentAdvancedSettings | Where-Object { $_.Name -eq $this.MotdSettingName }
    	$currentIssue = $VMHostCurrentAdvancedSettings | Where-Object { $_.Name -eq $this.IssueSettingName }

    	$this.SetAdvancedSetting($currentMotd, $this.Motd, $currentMotd.Value, $this.MotdClear)
        $this.SetAdvancedSetting($currentIssue, $this.Issue, $currentIssue.Value, $this.IssueClear)
    }

    <#
    .DESCRIPTION

    Populates the result returned from the Get() method with the values of the advanced settings from the server.
    #>
    [void] PopulateResult($VMHost, $result) {
    	Write-Verbose -Message "$(Get-Date) $($s = Get-PSCallStack; "Entering {0}" -f $s[0].FunctionName)"

    	$VMHostCurrentAdvancedSettings = Get-AdvancedSetting -Server $this.Connection -Entity $VMHost

    	$currentMotd = $VMHostCurrentAdvancedSettings | Where-Object { $_.Name -eq $this.MotdSettingName }
    	$currentIssue = $VMHostCurrentAdvancedSettings | Where-Object { $_.Name -eq $this.IssueSettingName }

    	$result.Motd = $currentMotd.Value
        $result.Issue = $currentIssue.Value
    }
}

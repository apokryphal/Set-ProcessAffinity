function Set-ProcessAffinity {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)][String] $Target,
		# Approximate regex for e.g. '1-12,17,19-20'
		[ValidatePattern('([0-9]+[,\-]+){0,}[0-9]+')]
		[Parameter(Mandatory, Position = 1)]
		[String] $TargetCores
	)
	$Target = $Target.TrimEnd('.exe')
	$Target = $Target.Split('\')[-1]

	# Create a usable index list from the provided core list
	$CoreList = New-Object Collections.Generic.List[Object]
	$TargetCores.Split(',') | ForEach-Object {
		if ( $_.Contains('-') ) {
			$RangeStart, $RangeEnd = $_.Split('-')
			$CoreList.AddRange($RangeStart .. $RangeEnd)
		} else {
			$CoreList.Add($_)
		}
	}

	$CoreMaskList = New-Object Collections.Generic.List[Object]
	# Create an empty mask in list form
	0 .. ($env:NUMBER_OF_PROCESSORS - 1) | ForEach-Object { $CoreMaskList.Add('0') }
	# Use the core list values as indices for masked bits 
	$CoreList | ForEach-Object { $CoreMaskList[$_] = '1' }
	# Join the list into a string
	$CoreMaskBin = $CoreMaskList -join ''
	# The mask is backwards, so flip it around
	$CoreMaskBin = $CoreMaskBin[-1 .. -($CoreMaskBin.Length)] -join ''
	# convert to an integer value
	$CoreAffinityMask = [Convert]::ToInt64($CoreMaskBin, 2)

	# Get the process and assign the affinity
	$Process = Get-Process -Name $Target
	$Process.ProcessorAffinity = $CoreAffinityMask
}

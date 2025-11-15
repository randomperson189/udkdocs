class YourAchievementHandler extends Actor;

// Array of all downloads achievements
var array<AchievementDetails> DownloadedAchievements;
// Pending achievements
var array<int> PendingAchievements;
// True if we're currently processing achievements
var bool ProcessingAchievements;

/** 
 * Called when the actor is destroyed
 */
event Destroyed()
{
	local OnlineSubsystem OnlineSubsystem;
	local int PlayerControllerId;

	Super.Destroyed();

	// Ensure we have an online subsystem, and an associated player interface
	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if (OnlineSubsystem == None || OnlineSubsystem.PlayerInterface == None)
	{
		return;
	}

	// If we're still processing achievements, delegates assigned must be clear so that garbage collection can occur
	if (ProcessingAchievements)
	{
		// Grab the local player controller id
		PlayerControllerId = GetALocalPlayerControllerId();

		// Remove the delegate reference so that garbage collection can occur
		OnlineSubsystem.PlayerInterface.ClearReadAchievementsCompleteDelegate(PlayerControllerId, InternalOnReadAchievementsComplete);

		// Clear the delegate bind
		OnlineSubsystem.PlayerInterface.ClearUnlockAchievementCompleteDelegate(PlayerControllerId, InternalOnUnlockAchievementComplete);
	}
}

/**
 * Unlocks an achievement for the player
 *
 * @param		AchievementId			Which achievement to unlock
 * @param		LocalUserNum			Local user index
 */
function UnlockAchievement(int AchievementId)
{
	local OnlineSubsystem OnlineSubsystem;
	local int PlayerControllerId;

	// This achievement is already pending, and is in progress so just wait
	if (PendingAchievements.Find(AchievementId) != INDEX_NONE)
	{
		return;
	}
	
	// Add the achievement id to the pending list
	PendingAchievements.AddItem(AchievementId);

	// If we're not processing achievements right now, process one now
	if (!ProcessingAchievements)
	{
		// Connect to GameCenter and link up the achievement delegates
		OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
		if (OnlineSubsystem != None && OnlineSubsystem.PlayerInterface != None)
		{
			// Grab the local player controller id
			PlayerControllerId = GetALocalPlayerControllerId();

			// Assign the read achievements delegate
			OnlineSubsystem.PlayerInterface.AddReadAchievementsCompleteDelegate(PlayerControllerId, InternalOnReadAchievementsComplete);
			
			// Read all achievements 
			OnlineSubsystem.PlayerInterface.ReadAchievements(PlayerControllerId);

			// set true, to prevent this from being fired off again
			ProcessingAchievements = true;
		}
	}
}

/**
 * Called when the async achievements read has completed
 *
 * @param		TitleId			The title id that the read was for (0 means current title)
 */
function InternalOnReadAchievementsComplete(int TitleId)
{
	local OnlineSubsystem OnlineSubsystem;
	local int AchievementIndex, PlayerControllerId;

	// Ensure we have an online subsystem, and an associated player interface
	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if (OnlineSubsystem == None || OnlineSubsystem.PlayerInterface == None)
	{
		return;
	}

	// Grab the local player controller id
	PlayerControllerId = GetALocalPlayerControllerId();

	// Clear the currently downloaded achievements array as we're copying the fresh data
	DownloadedAchievements.Remove(0, DownloadedAchievements.Length);

	// Read the achievements into the downloaded achievements array
	OnlineSubsystem.PlayerInterface.GetAchievements(PlayerControllerId, DownloadedAchievements, TitleId);

	// Grab all of the achievements
	if (DownloadedAchievements.Length > 0 && PendingAchievements.Length > 0)
	{
		// Grab the achievement index
		AchievementIndex = DownloadedAchievements.Find('Id', PendingAchievements[0]);

		// Unlock the achievement		
		if (AchievementIndex != INDEX_NONE && !DownloadedAchievements[AchievementIndex].bWasAchievedOnline)
		{
			// Assign the unlock achievement complete delegate
			OnlineSubsystem.PlayerInterface.AddUnlockAchievementCompleteDelegate(PlayerControllerId, InternalOnUnlockAchievementComplete);
			
			// Start the unlocking process
			OnlineSubsystem.PlayerInterface.UnlockAchievement(PlayerControllerId, PendingAchievements[0]);			
		}
	}

	// Remove the delegate reference so that garbage collection can occur
	OnlineSubsystem.PlayerInterface.ClearReadAchievementsCompleteDelegate(PlayerControllerId, InternalOnReadAchievementsComplete);
}

/**
 * Called when the achievement unlocking has completed
 *
 * @param bWasSuccessful true if the async action completed without error, false if there was an error
 */
function InternalOnUnlockAchievementComplete(bool bWasSuccessful)
{
	local OnlineSubsystem OnlineSubsystem;
	local PlayerController PlayerController;
	local int AchievementIndex, PlayerControllerId;

	// Grab the local player controller id
	PlayerControllerId = GetALocalPlayerControllerId();

	if (bWasSuccessful && PendingAchievements.Length > 0)
	{
		// Grab the local player controller
		PlayerController = GetALocalPlayerController();
		if (PlayerController != None)
		{
			// Grab the achievement index
			AchievementIndex = DownloadedAchievements.Find('Id', PendingAchievements[0]);

			// Show the achievement on the user interface players
		}
	}

	// Pop the processed achievement regardless of whether it succeeded or not
	PendingAchievements.Remove(0, 1);

	// Ensure we have an online subsystem, and an associated player interface
	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if (OnlineSubsystem == None || OnlineSubsystem.PlayerInterface == None)
	{
		return;
	}

	// If we still have pending achievements left, process the next one
	if (PendingAchievements.Length > 0)
	{
		// Connect to GameCenter and link up the achievement delegates
		// Assign the read achievements delegate
		OnlineSubsystem.PlayerInterface.AddReadAchievementsCompleteDelegate(PlayerControllerId, InternalOnReadAchievementsComplete);
			
		// Read all achievements 
		OnlineSubsystem.PlayerInterface.ReadAchievements(PlayerControllerId);
	}
	else // Otherwise, we're finished so clean up
	{
		// Clear the delegate bind
		OnlineSubsystem.PlayerInterface.ClearUnlockAchievementCompleteDelegate(PlayerControllerId, InternalOnUnlockAchievementComplete);

		// Set the flag to state that we're no longer processing achievements
		ProcessingAchievements = false;
	}
}

/**
 * Returns a local player controller id. Same rules apply to Actor::GetALocalPlayerController().
 *
 * @return		Returns a local player controller id
 */
function int GetALocalPlayerControllerId()
{
	local PlayerController PlayerController;
	local LocalPlayer LocalPlayer;

	// Get the local player controller
	PlayerController = GetALocalPlayerController();
	if (PlayerController == None)
	{
		return INDEX_NONE;
	}

	// Get the local player information
	LocalPlayer = LocalPlayer(PlayerController.Player);
	if (LocalPlayer == None)
	{
		return INDEX_NONE;
	}

	return class'UIInteraction'.static.GetPlayerIndex(LocalPlayer.ControllerId);
}

defaultproperties
{
}
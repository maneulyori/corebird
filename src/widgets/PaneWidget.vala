
using Gtk;


/**
 * Fun stuff: every subclass of this 'Widget' must provide some kind of 
 * ID that identifies its content.
 * Example:
 *   If TweetWidget implements PaneWidget it could easily provide the 
 *   tweet's ID for its id.
**/
interface PaneWidget : Widget {
	public abstract string get_id();
}
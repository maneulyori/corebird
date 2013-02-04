using Gtk;

/**
 * A normal box, but with an image as background.
 * The image will always be drawn at the upper left corner
 * and it won't be stretched.(TODO: Change this)
 */
class ImageBox : Gtk.Box  {
	private static const float RATIO = (160f/320f);
	public Gdk.Pixbuf pixbuf;

	public ImageBox(Orientation orientation, int spacing){
		GLib.Object(orientation: orientation, spacing: spacing);
	}

	public override bool draw(Cairo.Context c){

		Allocation alloc;
		this.get_allocation(out alloc);
		var sc = this.get_style_context();

		//Boxes do not draw any background! YAY
		sc.render_background(c, 0, 0, alloc.width, alloc.height);
		base.draw(c);
		return false;
	}

	public override void get_preferred_height_for_width(int width, out int min_height,
	                                                    out int natural_height){
		min_height = (int)(width * RATIO);
		natural_height = (int)(width * RATIO);
	}

	public override SizeRequestMode get_request_mode(){
		return SizeRequestMode.HEIGHT_FOR_WIDTH;
	}
}
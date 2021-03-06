/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;

[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-page.ui")]
class DMPage : IPage, IMessageReceiver, Box {
  public int unread_count                   { get { return 0; } }
  public unowned MainWindow main_window     { get; set; }
  public unowned Account account            { get; set; }
  public unowned DeltaUpdater delta_updater { get; set; }
  public int id                             { get; set; }
  [GtkChild]
  private Button send_button;
  [GtkChild]
  private Entry text_entry;
  [GtkChild]
  private ListBox messages_list;
  [GtkChild]
  private ScrollWidget scroll_widget;
  private DMPlaceholderBox placeholder_box = new DMPlaceholderBox ();

  public int64 user_id;
  private int64 lowest_id = int64.MAX;

  public DMPage (int id) {
    this.id = id;
    text_entry.buffer.inserted_text.connect (recalc_length);
    text_entry.buffer.deleted_text.connect (recalc_length);
    messages_list.set_sort_func (ITwitterItem.sort_func_inv);
    placeholder_box.show ();
    messages_list.set_placeholder(placeholder_box);
    scroll_widget.scrolled_to_start.connect (load_older);
  }

  public void stream_message_received (StreamMessageType type, Json.Node root) { // {{{
    if (type == StreamMessageType.DIRECT_MESSAGE) {
      // Arriving new dms get already cached in the DMThreadsPage
      var obj = root.get_object ().get_object_member ("direct_message");
      if (obj.get_int_member ("sender_id") != this.user_id)
        return;

      var text = obj.get_string_member ("text");
      if (obj.has_member ("entities")) {
        var urls = obj.get_object_member ("entities").get_array_member ("urls");
        var url_list = new GLib.SList<TweetUtils.Sequence?> ();
        urls.foreach_element((arr, index, node) => {
          var url = node.get_object();
          string expanded_url = url.get_string_member("expanded_url");

          Json.Array indices = url.get_array_member ("indices");
          expanded_url = expanded_url.replace("&", "&amp;");
          url_list.prepend(TweetUtils.Sequence() {
            start = (int)indices.get_int_element (0),
            end   = (int)indices.get_int_element (1) ,
            url   = expanded_url,
            display_url = url.get_string_member ("display_url"),
            visual_display_url = false
          });
        });
        text = TweetUtils.get_formatted_text (text, url_list);
      }

      var sender = obj.get_object_member ("sender");
      var new_msg = new DMListEntry ();
      new_msg.text = obj.get_string_member ("text");
      new_msg.name = sender.get_string_member ("name");
      new_msg.screen_name = sender.get_string_member ("screen_name");
      new_msg.avatar_url = sender.get_string_member ("profile_image_url");
      new_msg.timestamp = Utils.parse_date (obj.get_string_member ("created_at")).to_unix ();
      new_msg.main_window = main_window;
      new_msg.user_id = sender.get_int_member ("id");
      new_msg.load_avatar ();
      new_msg.update_time_delta ();
      delta_updater.add (new_msg);
      messages_list.add (new_msg);
      if (scroll_widget.scrolled_down)
        scroll_widget.scroll_down_next ();
    }
  } /// }}}

  private void load_older () { // {{{
    var now = new GLib.DateTime.now_local ();
    scroll_widget.balance_next_upper_change (TOP);
    // Load messages
    // TODO: Fix code duplication
    account.db.select ("dms").cols ("from_id", "to_id", "text", "from_name", "from_screen_name",
                                    "avatar_url", "timestamp", "id")
              .where (@"(`from_id`='$user_id' OR `to_id`='$user_id') AND `id` < '$lowest_id'")
              .order ("timestamp DESC")
              .limit (35)
              .run ((vals) => {
      int64 id = int64.parse (vals[7]);
      if (id < lowest_id)
        lowest_id = id;

      var entry = new DMListEntry ();
      entry.id = id;
      entry.user_id = int64.parse (vals[0]);
      entry.timestamp = int64.parse (vals[6]);
      entry.text = vals[2];
      entry.name = vals[3];
      entry.screen_name = vals[4];
      entry.avatar_url = vals[5];
      entry.main_window = main_window;
      entry.load_avatar ();
      entry.update_time_delta (now);
      delta_updater.add (entry);
      messages_list.add (entry);
      return true;
    });

  } // }}}

  public void on_join (int page_id, va_list arg_list) { // {{{
    int64 user_id = arg_list.arg<int64> ();
    if (user_id == 0)
      return;

    this.lowest_id = int64.MAX;
    this.user_id = user_id;
    string screen_name;
    string name = null;
    if ((screen_name = arg_list.arg<string> ()) != null) {
      name = arg_list.arg<string> ();
      placeholder_box.screen_name = screen_name;
      placeholder_box.name = name;
      placeholder_box.avatar_url = arg_list.arg<string> ();
      placeholder_box.load_avatar ();
    }

    //Clear list
    messages_list.foreach ((w) => {messages_list.remove (w);});

    var now = new GLib.DateTime.now_local ();
    // Load messages
    account.db.select ("dms").cols ("from_id", "to_id", "text", "from_name", "from_screen_name",
                                    "avatar_url", "timestamp", "id")
              .where (@"`from_id`='$user_id' OR `to_id`='$user_id'")
              .order ("timestamp DESC")
              .limit (35)
              .run ((vals) => {
      int64 id = int64.parse (vals[7]);
      if (id < lowest_id)
        lowest_id = id;

      var entry = new DMListEntry ();
      entry.id = id;
      entry.user_id = int64.parse (vals[0]);
      entry.timestamp = int64.parse (vals[6]);
      entry.text = vals[2];
      entry.name = vals[3];
      name = vals[3];
      entry.screen_name = vals[4];
      screen_name = vals[4];
      entry.avatar_url = vals[5];
      entry.main_window = main_window;
      entry.load_avatar ();
      entry.update_time_delta (now);
      delta_updater.add (entry);
      messages_list.add (entry);
      return true;
    });

    account.user_counter.user_seen (user_id, screen_name, name);

    scroll_widget.scroll_down_next (false, true);

    // Focus the text entry
    text_entry.grab_focus ();
  } // }}}

  public void on_leave () {}

  [GtkCallback]
  private void send_button_clicked_cb () { // {{{
    if (text_entry.buffer.length == 0 || text_entry.buffer.length > Tweet.MAX_LENGTH)
      return;

    // Just add the entry now
    DMListEntry entry = new DMListEntry ();
    entry.screen_name = account.screen_name;
    entry.timestamp = new GLib.DateTime.now_local ().to_unix ();
    entry.text = text_entry.text;
    entry.name = account.name;
    entry.avatar = account.avatar;
    entry.update_time_delta ();
    delta_updater.add (entry);
    messages_list.add (entry);
    var call = account.proxy.new_call ();
    call.set_function ("1.1/direct_messages/new.json");
    call.set_method ("POST");
    call.add_param ("user_id", user_id.to_string ());
    call.add_param ("text", text_entry.text);
    call.invoke_async.begin (null, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        Utils.show_error_object (call.get_payload (), e.message);
        return;
      }
    });

    // clear the text entry
    text_entry.text = "";

    // Scroll down
    if (scroll_widget.scrolled_down)
      scroll_widget.scroll_down_next ();
  } // }}}

  private void recalc_length () {
    uint text_length = text_entry.buffer.length;
    send_button.sensitive = text_length > 0 && text_length < 140;
  }


  public string? get_title () {
    return _("Direct Conversation");
  }

  public void create_tool_button(RadioToolButton? group) {}
  public RadioToolButton? get_tool_button() {return null;}
}

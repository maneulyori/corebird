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

[GtkTemplate (ui = "/org/baedert/corebird/ui/dm-threads-page.ui")]
class DMThreadsPage : IPage, IMessageReceiver, ScrollWidget {
  public int unread_count { get;set; }
  public unowned MainWindow main_window {set; get;}
  protected Gtk.ListBox tweet_list {set; get;}
  public Account account {get; set;}
  private int id;
  private BadgeRadioToolButton tool_button;
  private bool loading = false;
  protected uint tweet_remove_timeout{get;set;}
  private ProgressEntry progress_entry = new ProgressEntry(75);
  public DeltaUpdater delta_updater {get;set;}
  [GtkChild]
  private Gtk.ListBox thread_list;


  public DMThreadsPage (int id) {
    this.id = id;
  }

  public void stream_message_received (StreamMessageType type, Json.Node root) {

  }


  public void on_join (int page_id, va_list arg_list) {
    var call = account.proxy.new_call ();
    call.set_function ("1.1/direct_messages.json");
    call.set_method ("GET");
    call.invoke_async (null, () => {
      var parser = new Json.Parser ();
      parser.load_from_data (call.get_payload ());
      var gen = new Json.Generator ();
      gen.root = parser.get_root ();
      gen.pretty = true;
      stdout.printf (gen.to_data(null)+"\n");
    });
  }

  public void load_cached () {

  }

  public void load_newest () {

  }

  public void load_older () {

  }





  public void create_tool_button(RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "dms");
    tool_button.label = "Home";
  }

  public RadioToolButton? get_tool_button() {
    return tool_button;
  }

  public int get_id() {
    return id;
  }

  private void update_unread_count() {
    tool_button.show_badge = (unread_count > 0);
    tool_button.queue_draw();
  }

}
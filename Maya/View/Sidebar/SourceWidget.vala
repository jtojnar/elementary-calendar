namespace Maya.View {
    
    /**
     * A widget containing one source to be displayed in the sidebar.
     */
    public class SourceWidget : Gtk.VBox {

        // The label displaying the name of this source.
        Gtk.Label name_label;
        
        // The selected date
        DateTime selected_date;

        // All of the events of the current date range in the CalendarView
        Gee.ArrayList<E.CalComponent> events;

        // All the widgets associated with the current day
        Gee.Map<E.CalComponent, EventWidget> event_widgets;

        // A boolean indicating whether this source is currently selected
        public bool selected {get; set;}

        // TODO style

        /**
         * Creates a new source widget for the given source.
         */
        public SourceWidget (E.Source source) {

            // TODO: hash and equal funcs are in util but cause a crash
            // (both for map and list)
            event_widgets = new Gee.HashMap<E.CalComponent, EventWidget> (
                null,
                null,
                null);

            events = new Gee.ArrayList<E.CalComponent> (null);

            name_label = new Gtk.Label (source.peek_name ());
            name_label.set_alignment (0, 0.5f);
            pack_start (name_label, false, true, 0);

            notify["selected"].connect (update_visibility);
        }

        /**
         * Updates whether this widget should currently be shown or not.
         */
        void update_visibility () {
            stdout.printf ("VIS %s , %d\n", selected ? "true" : "false", event_widgets.size);
            if (selected && event_widgets.size > 0)
                show_all ();
            else
                hide ();
        }

        /**
         * Called when the given event for this source is added.
         */
        public void add_event (E.CalComponent event) {
            // TODO: check this
            if (event_widgets.has_key (event))
                remove_event (event);

            events.add (event);

            if (event_in_current_date (event)) {
                show_event (event);
            }
        }

        /**
         * Called when the given event for this source is removed.
         */
        public void remove_event (E.CalComponent event) {
            if (!events.contains (event))
                return;

            events.remove (event);

            if (event_widgets.has_key (event)) {
                hide_event (event);
            }
        }

        /**
         * Called when the given event for this source is updated.
         */
        public void update_event (E.CalComponent event) {
            if (!events.contains (event))
                return;

            events.remove (event);
            events.add (event);

            if (event_widgets.has_key (event)) {
                event_widgets.get (event).update (event);
            }
        }

        /**
         * Called when the selected date in the calendarview is changed.
         */
        public void set_selected_date (DateTime date) {
            selected_date = date;

            foreach (var event in events) {
                if (event_in_current_date (event) && !event_widgets.has_key (event)) {
                    show_event (event);
                } else if (!event_in_current_date (event) && event_widgets.has_key (event)) {
                    var widget = event_widgets.get (event);
                    event_widgets.unset (event);
                    widget.destroy ();
                }
            }

            update_visibility ();
        }

        /**
         * Creates a widget to show the given event.
         */
        void show_event (E.CalComponent event) {
            EventWidget widget = new EventWidget (event);
            pack_start (widget, true, true, 0);
            widget.show_all ();

            event_widgets.set (event, widget);
        }
    
        /**
         * Destroys the widget associated with the given event.
         */
        void hide_event (E.CalComponent event) {
            var widget = event_widgets.get (event);
            event_widgets.unset (event);
            widget.destroy ();
        }

        /**
         * Indicates if the given event is in the currently selected date.
         */
        bool event_in_current_date (E.CalComponent event) {
            if (selected_date == null)
                return false;

            unowned iCal.icalcomponent comp = event.get_icalcomponent ();

            iCal.icaltimetype time = comp.get_dtstart ();

            DateTime start_date = Util.ical_to_date_time (time);

            if (start_date.get_year () == selected_date.get_year () && 
                start_date.get_day_of_year () == selected_date.get_day_of_year ())
                return true;
            else
                return false;

        }

        /**
         * Removes all events from the event list.
         */
        public void remove_all_events () {
            foreach (var widget in event_widgets.values) {
                widget.destroy ();
            }
            events.clear ();
            event_widgets.clear ();
        }

    }

}

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Runtime.CompilerServices;
using Avalonia;
using Avalonia.Controls;
using Avalonia.LogicalTree;

namespace HordesOfAzeroth.Launcher
{
    static class Loc
    {
        sealed class Shown
        {
            public string English;
            public string Text;
        }

        static readonly Dictionary<string, Dictionary<string, string>> Tables = new Dictionary<string, Dictionary<string, string>>
        {
            ["zhCN"] = LocZhCN.Strings,
        };

        static readonly ConditionalWeakTable<AvaloniaObject, Dictionary<AvaloniaProperty, Shown>> Originals =
            new ConditionalWeakTable<AvaloniaObject, Dictionary<AvaloniaProperty, Shown>>();

        static Dictionary<string, string> s_table;

        public static void Use(string code) => Tables.TryGetValue(code, out s_table);

        public static string Key(string english) => english;

        public static string T(string english) =>
            s_table != null && s_table.TryGetValue(english, out string text) ? text : english;

        public static string T(string english, params object[] values) =>
            string.Format(CultureInfo.InvariantCulture, T(english), values);

        public static void Apply(Control root)
        {
            foreach (Control control in Controls(root, new HashSet<Control>()))
            {
                if (control is Window)
                    Translate(control, Window.TitleProperty);
                if (control is TextBlock block && (block.Inlines == null || block.Inlines.Count == 0))
                    Translate(control, TextBlock.TextProperty);
                if (control is ContentControl)
                    Translate(control, ContentControl.ContentProperty);
                if (control is MenuItem)
                    Translate(control, MenuItem.HeaderProperty);
                Translate(control, ToolTip.TipProperty);
            }
        }

        static IEnumerable<Control> Controls(Control control, HashSet<Control> seen)
        {
            if (!seen.Add(control))
                yield break;
            yield return control;
            List<Control> children = new List<Control>();
            foreach (ILogical child in control.GetLogicalChildren())
                if (child is Control inner)
                    children.Add(inner);
            if (control is ItemsControl items)
                foreach (object item in items.Items)
                    if (item is Control inner)
                        children.Add(inner);
            if (control.ContextMenu != null)
                children.Add(control.ContextMenu);
            foreach (Control child in children)
                foreach (Control found in Controls(child, seen))
                    yield return found;
        }

        static void Translate(AvaloniaObject target, AvaloniaProperty property)
        {
            if (!(target.GetValue(property) is string current) || current.Length == 0)
                return;
            Dictionary<AvaloniaProperty, Shown> shown = Originals.GetOrCreateValue(target);
            string english = shown.TryGetValue(property, out Shown last) && last.Text == current ? last.English : current;
            string text = T(english);
            shown[property] = new Shown { English = english, Text = text };
            if (text != current)
                target.SetValue(property, text);
        }
    }
}

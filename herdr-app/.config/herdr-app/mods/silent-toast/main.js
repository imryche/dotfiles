import { View, div } from "gpui-kit";
import { closeOverlay, props } from "herdr";

export default class SilentToast extends View {
  init() {
    const overlay = props()?.overlay;
    if (overlay) closeOverlay(overlay);
  }

  render() {
    return div();
  }
}

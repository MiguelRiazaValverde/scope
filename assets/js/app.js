// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"



let zIndex = 1;
const memory = {};


function drag(ctx) {
  const el = ctx.el.querySelector(".draggable");
  let pos = { x: 0, y: 0, left: 0, top: 0 };
  let dragging = false;

  const getCurrentPosition = () => {
    const parent = el.parentElement;
    return {
      left: parseInt(parent.style.left || 0, 10),
      top: parseInt(parent.style.top || 0, 10)
    };
  };

  const onMouseDown = (e) => {
    if (e.target !== el) return;

    dragging = true;
    const { left, top } = getCurrentPosition();

    ctx.el.style.zIndex = zIndex++;

    if (!memory[ctx.el.id])
      memory[ctx.el.id] = [];

    memory[ctx.el.id].zIndex = ctx.el.style.zIndex;

    pos = {
      x: e.clientX,
      y: e.clientY,
      left,
      top
    };

    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("mouseup", onMouseUp);
    e.preventDefault();
  };

  const onMouseMove = (e) => {
    if (!dragging) return;
    const dx = e.clientX - pos.x;
    const dy = e.clientY - pos.y;

    const newLeft = pos.left + dx;
    const newTop = pos.top + dy;

    const parent = el.parentElement;
    parent.style.position = "absolute";
    parent.style.left = newLeft + "px";
    parent.style.top = newTop + "px";

    memory[ctx.el.id] = { left: newLeft, top: newTop, zIndex: memory[ctx.el.id]?.zIndex || 0 };
  };

  const onMouseUp = (e) => {
    dragging = false;
    window.removeEventListener("mousemove", onMouseMove);
    window.removeEventListener("mouseup", onMouseUp);
  };

  el.addEventListener("mousedown", onMouseDown);

  ctx.destroyed = () => {
    el.removeEventListener("mousedown", onMouseDown);
    window.removeEventListener("mousemove", onMouseMove);
    window.removeEventListener("mouseup", onMouseUp);
    delete memory[this.el.id];
  };
}



let Hooks = {};

Hooks.Draggable = {
  mounted() {
    drag(this);
  },
  updated() {
    const mem = memory[this.el.id];
    if (mem) {
      this.el.style.position = "absolute";
      this.el.style.left = mem.left + "px";
      this.el.style.top = mem.top + "px";
      this.el.style.zIndex = mem.zIndex || 0;
    }
  }
};





let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


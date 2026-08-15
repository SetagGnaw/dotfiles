function dstop() {
  pkill -9 Docker
  pkill -9 com.docker
}

function dstart() {
  open -a Docker
}

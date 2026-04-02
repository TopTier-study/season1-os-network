# echo_server.py
import socket

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', 9999))
server.listen(1)
print("서버 대기 중... (포트 9999)")

while True:
    conn, addr = server.accept()
    print(f"연결됨: {addr}")
    while True:
        data = conn.recv(1024)
        if not data:
            print(f"연결 종료: {addr}")
            break
        print(f"수신: {data.decode()}")
        conn.sendall(data)  # 에코
    conn.close()
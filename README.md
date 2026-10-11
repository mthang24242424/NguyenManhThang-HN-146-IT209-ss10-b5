# Bài 5: Tự động hóa điều phối đa dịch vụ với Docker Compose & File .env

## Mục tiêu

Đóng gói bài Ex4 thành tệp khai báo `docker-compose.yml` theo chuẩn **Infrastructure as Code (IaC)** — quản lý toàn bộ hạ tầng đa container bằng một lệnh duy nhất.

---

## Cấu trúc thư mục

```
Ex5/
├── docker-compose.yml   ← Khai báo 2 services: backend + database
├── .env                 ← Biến môi trường thực tế (KHÔNG commit lên Git)
├── .env.example         ← Mẫu biến môi trường (commit lên Git)
├── .gitignore           ← Loại trừ .env khỏi Git
└── README.md
```

---

## Kiến trúc

```
┌──────────────────────────────────────────────────────┐
│              Docker Compose Stack                    │
│                                                      │
│  ┌─────────────────┐  depends_on  ┌───────────────┐ │
│  │    backend      │─────────────▶│   database    │ │
│  │  (nginx:alpine) │   DNS: database  (postgres)  │ │
│  │  port ${PORT}:80│              │  healthcheck  │ │
│  └────────┬────────┘              └───────┬───────┘ │
│           │                               │         │
│           └──────── backend-net ──────────┘         │
│                    (bridge / app-net)                │
│                               │ mount               │
│                         ┌─────▼──────┐              │
│                         │   pgdata   │              │
│                         │  (db-data) │              │
│                         └────────────┘              │
└──────────────────────────────────────────────────────┘
```

---

## Cách chạy

### 1. Chuẩn bị file .env

```bash
cp .env.example .env
# Chỉnh sửa .env nếu cần thay đổi password hoặc port
```

Nội dung `.env`:
```env
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=secret123
PORT=8080
```

### 2. Khởi chạy toàn bộ stack

```bash
docker compose up -d
```

Docker Compose sẽ tự động:
- Tạo network `app-net` (bridge)
- Tạo volume `db-data`
- Khởi chạy `database` (postgres:15-alpine)
- Chờ `database` healthy rồi mới khởi chạy `backend`

### 3. Kiểm tra trạng thái

```bash
# Xem trạng thái các service
docker compose ps

# Xem logs realtime
docker compose logs -f

# Xem logs riêng từng service
docker compose logs database
docker compose logs backend
```

### 4. Dừng và dọn dẹp

```bash
# Dừng và xóa containers + network (giữ lại volume)
docker compose down

# Dừng và xóa tất cả bao gồm cả volume (XÓA DỮ LIỆU)
docker compose down -v
```

---

## Giải thích `docker-compose.yml`

### Service `database`

```yaml
database:
  image: postgres:15-alpine
  environment:
    POSTGRES_DB: ${DB_NAME}       # Đọc từ file .env
    POSTGRES_USER: ${DB_USER}
    POSTGRES_PASSWORD: ${DB_PASSWORD}
  volumes:
    - pgdata:/var/lib/postgresql/data
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
```

- Biến `${DB_*}` được nạp tự động từ file `.env` cùng thư mục.
- `healthcheck` dùng `pg_isready` để xác nhận Postgres thực sự sẵn sàng nhận kết nối.

### Service `backend`

```yaml
backend:
  environment:
    DB_HOST: database             # Tên service = hostname DNS nội bộ
  depends_on:
    database:
      condition: service_healthy  # Chờ healthcheck xanh
```

- `DB_HOST: database` — Docker Compose DNS tự phân giải `database` thành IP container.
- `condition: service_healthy` đảm bảo backend không khởi động trước khi DB sẵn sàng.

### Root-level `volumes` & `networks`

```yaml
volumes:
  pgdata:
    name: db-data      # Tên volume cố định, dễ nhận biết

networks:
  backend-net:
    driver: bridge
    name: app-net      # Tên network cố định
```

Khai báo ở root level bắt buộc khi muốn dùng `name` tùy chỉnh và chia sẻ giữa nhiều service.

---

## So sánh Ex4 (CLI) vs Ex5 (Compose)

| Tiêu chí | Ex4 — Docker CLI | Ex5 — Docker Compose |
|---|---|---|
| Cách khởi chạy | Chạy từng lệnh `docker run` | Một lệnh `docker compose up -d` |
| Quản lý cấu hình | Hardcode trong script | Khai báo YAML + `.env` |
| Bảo mật secrets | Lộ trong lệnh CLI | Tách vào `.env`, không commit |
| Thứ tự khởi động | Thủ công (sleep) | `depends_on` + `healthcheck` |
| Reproducibility | Thấp | Cao (IaC) |

---

## Sản phẩm nộp bài

- [x] `docker-compose.yml` — khai báo 2 services với `depends_on`, `networks`, `volumes`
- [x] `.env.example` — mẫu biến môi trường
- [x] `.gitignore` — loại trừ `.env` thực tế
- [x] `README.md` — tài liệu hướng dẫn

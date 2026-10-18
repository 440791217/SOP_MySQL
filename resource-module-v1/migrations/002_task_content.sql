-- Additive task-owned content mapping. MySQL 8.4 / InnoDB.
-- Select sop_dev explicitly. Does not delete or rewrite any existing data.
CREATE TABLE IF NOT EXISTS sop_task_content (
 task_id BIGINT NOT NULL PRIMARY KEY,
 sop_id BIGINT NOT NULL,
 created_by BIGINT NOT NULL,
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 CONSTRAINT uk_task_content_sop UNIQUE (sop_id),
 CONSTRAINT fk_task_content_task FOREIGN KEY(task_id) REFERENCES sop_task(id),
 CONSTRAINT fk_task_content_sop FOREIGN KEY(sop_id) REFERENCES sop_document(id),
 CONSTRAINT fk_task_content_creator FOREIGN KEY(created_by) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

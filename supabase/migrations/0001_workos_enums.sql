-- Brilliants Work OS — Migration 0001: Enums
-- Run order: first

-- User roles within a company
create type public.workos_user_role as enum (
  'OWNER', 'ADMIN', 'MANAGER', 'MEMBER'
);

-- Task status lifecycle
create type public.task_status as enum (
  'TODO', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
);

-- Task priority levels
create type public.task_priority as enum (
  'LOW', 'MEDIUM', 'HIGH', 'URGENT'
);

-- Department categories
create type public.department as enum (
  'SALES', 'MARKETING', 'DEVELOPMENT', 'SUPPORT', 'OPERATIONS', 'OTHER'
);

-- Target metric types
create type public.target_type as enum (
  'SALES', 'LEADS', 'CALLS', 'MEETINGS', 'DEMOS', 'CONVERSIONS',
  'REVENUE', 'POSTS', 'REELS', 'BLOGS', 'BUGS_RESOLVED',
  'FEATURES', 'TICKETS', 'TASKS_COMPLETED', 'CUSTOM'
);

-- Performance rating bands
create type public.performance_band as enum (
  'EXCELLENT', 'GOOD', 'AVERAGE', 'NEEDS_ATTENTION'
);

-- Notification channels
create type public.notification_channel as enum (
  'IN_APP', 'EMAIL', 'WHATSAPP'
);

-- Recurring task frequency
create type public.recurrence_type as enum (
  'DAILY', 'WEEKLY', 'MONTHLY', 'CUSTOM'
);

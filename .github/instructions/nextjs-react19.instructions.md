---
description: "Next.js and React 19 frontend instruction covering Server Components, App Router, streaming, form actions, and modern patterns"
applyTo: "**/*.tsx,**/*.ts,**/next.config.*"
---

# Next.js and React 19 Instruction

## Overview

This instruction covers best practices for building applications with Next.js using React 19, focusing on Server Components as the default paradigm, modern data fetching patterns, server actions, and streaming capabilities.

## React 19 Server Components

Use Server Components by default for all components that don't require interactivity. Server Components run exclusively on the server and never ship JavaScript to the browser.

```tsx
export default async function UserProfile({ id }: { id: string }) {
  const user = await fetchUser(id);

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}
```

Server Components provide:

- Direct access to backend resources
- Secure credential storage (API keys, tokens)
- Large dependency handling without increasing bundle size
- Automatic code splitting

For components requiring interactivity, mark them with the `"use client"` directive at the top of the file.

```tsx
"use client";

import { useState } from "react";

export default function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
}
```

## Server Actions

Server Actions are asynchronous functions that execute on the server and can be called from Client Components or Server Components. Use them for mutations, form submissions, and operations requiring server-side validation.

Define Server Actions with the `"use server"` directive:

```tsx
"use server";

export async function createPost(formData: FormData) {
  const title = formData.get("title");
  const content = formData.get("content");

  const post = await db.posts.create({
    title: String(title),
    content: String(content),
  });

  revalidatePath("/blog");
  redirect("/blog/" + post.id);
}
```

Call Server Actions from forms:

```tsx
import { createPost } from "./actions";

export default function NewPostForm() {
  return (
    <form action={createPost}>
      <input name="title" required />
      <textarea name="content" required />
      <button type="submit">Create Post</button>
    </form>
  );
}
```

## The use() Hook

The `use()` hook allows Client Components to consume promises returned from Server Components. This enables passing async data from parent Server Components to child Client Components.

```tsx
import { use } from "react";

async function getUser(id: string) {
  return fetch(`/api/users/${id}`).then((res) => res.json());
}

function UserDetailsClient({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);

  return <div>{user.name}</div>;
}

export default function UserLayout({ id }: { id: string }) {
  const userPromise = getUser(id);

  return <UserDetailsClient userPromise={userPromise} />;
}
```

## Next.js App Router Patterns

Structure your application using the App Router with the following conventions:

### Route Organization

```text
app/
  layout.tsx              # Root layout
  page.tsx                # Home page
  dashboard/
    layout.tsx            # Dashboard layout
    page.tsx              # Dashboard page
    settings/
      page.tsx            # Settings page
  api/
    users/
      route.ts            # API endpoint
```

### Dynamic Routes

Use `[slug]` for dynamic segments and `[...slug]` for catch-all routes:

```tsx
// app/posts/[id]/page.tsx
export default async function PostPage({ params }: { params: { id: string } }) {
  const post = await getPost(params.id);

  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.content}</p>
    </article>
  );
}
```

### Parallel Routes

Use `@slot` naming convention for parallel routes in complex layouts:

```text
app/
  dashboard/
    layout.tsx
    page.tsx
    @analytics/
      page.tsx
    @users/
      page.tsx
```

## Metadata API

Define page metadata using the Metadata API instead of `<head>` tags directly:

```tsx
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "My Blog",
  description: "A blog about Next.js and React",
  openGraph: {
    type: "website",
    url: "https://example.com",
    title: "My Blog",
    description: "A blog about Next.js and React",
  },
};

export default function Home() {
  return <main>Welcome to my blog</main>;
}
```

Generate dynamic metadata with `generateMetadata()`:

```tsx
export async function generateMetadata({ params }: { params: { id: string } }): Promise<Metadata> {
  const post = await getPost(params.id);

  return {
    title: post.title,
    description: post.excerpt,
  };
}

export default async function PostPage({ params }: { params: { id: string } }) {
  const post = await getPost(params.id);

  return <article>{post.content}</article>;
}
```

## Route Handlers

Use Route Handlers to create RESTful API endpoints with `route.ts` files:

```tsx
// app/api/posts/route.ts
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const posts = await db.posts.findMany();
  return NextResponse.json(posts);
}

export async function POST(request: NextRequest) {
  const data = await request.json();
  const post = await db.posts.create(data);
  return NextResponse.json(post, { status: 201 });
}
```

Handle dynamic routes and HTTP methods:

```tsx
// app/api/posts/[id]/route.ts
export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  const post = await db.posts.findUnique({ where: { id: params.id } });

  if (!post) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  return NextResponse.json(post);
}

export async function PUT(request: NextRequest, { params }: { params: { id: string } }) {
  const data = await request.json();
  const post = await db.posts.update({ where: { id: params.id }, data });
  return NextResponse.json(post);
}

export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  await db.posts.delete({ where: { id: params.id } });
  return new NextResponse(null, { status: 204 });
}
```

## Streaming and Suspense

Use Suspense to stream UI as data becomes available, improving perceived performance:

```tsx
import { Suspense } from "react";

function PostsSkeleton() {
  return <div className="skeleton">Loading posts...</div>;
}

async function Posts() {
  const posts = await getPosts();

  return (
    <ul>
      {posts.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  );
}

export default function Page() {
  return (
    <div>
      <h1>Blog</h1>
      <Suspense fallback={<PostsSkeleton />}>
        <Posts />
      </Suspense>
    </div>
  );
}
```

Combine multiple Suspense boundaries for progressive enhancement:

```tsx
export default function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>

      <Suspense fallback={<AnalyticsSkeleton />}>
        <Analytics />
      </Suspense>

      <Suspense fallback={<UsersSkeleton />}>
        <Users />
      </Suspense>
    </div>
  );
}
```

## React Compiler

The React Compiler automatically optimizes your components by memoizing values and functions. To enable it, update your `next.config.ts`:

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    reactCompiler: true,
  },
};

export default nextConfig;
```

The compiler eliminates the need for manual optimization utilities in most cases:

- Automatic `useMemo()` insertion
- Automatic `useCallback()` insertion
- Automatic value memoization
- Prevents unnecessary re-renders

When enabled, avoid manual memoization to allow the compiler to make optimal decisions.

## RSC Data Fetching Patterns

Fetch data directly in Server Components and avoid `useEffect()` with `useState()` for server-side data:

```tsx
// ✓ Good: Direct server-side fetch
export default async function Users() {
  const users = await fetch("https://api.example.com/users").then((res) => res.json());

  return (
    <ul>
      {users.map((user: User) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

```tsx
// ✗ Avoid: Client-side fetch with useEffect
"use client";

import { useEffect, useState } from "react";

export default function Users() {
  const [users, setUsers] = useState<User[]>([]);

  useEffect(() => {
    fetch("/api/users")
      .then((res) => res.json())
      .then(setUsers);
  }, []);

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

Use database queries or ORM directly in Server Components when possible:

```tsx
import { db } from "@/lib/db";

export default async function Users() {
  const users = await db.user.findMany();

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

## Form Actions and Validation

Combine Server Actions with form handling for seamless mutations:

```tsx
"use server";

import { revalidatePath } from "next/cache";

export async function updateProfile(formData: FormData) {
  const userId = formData.get("userId");
  const name = formData.get("name");
  const email = formData.get("email");

  // Validation
  if (!name || !email) {
    return { error: "Name and email are required" };
  }

  if (!email.includes("@")) {
    return { error: "Invalid email address" };
  }

  // Database update
  const user = await db.user.update({
    where: { id: String(userId) },
    data: {
      name: String(name),
      email: String(email),
    },
  });

  revalidatePath("/profile");

  return { success: true, user };
}
```

Use Client Components to handle form state and display results:

```tsx
"use client";

import { useActionState } from "react";
import { updateProfile } from "./actions";

export default function ProfileForm({ user }: { user: User }) {
  const [state, formAction, isPending] = useActionState(updateProfile, null);

  return (
    <form action={formAction}>
      <input type="hidden" name="userId" value={user.id} />

      <div>
        <label htmlFor="name">Name</label>
        <input id="name" name="name" defaultValue={user.name} required />
      </div>

      <div>
        <label htmlFor="email">Email</label>
        <input id="email" name="email" type="email" defaultValue={user.email} required />
      </div>

      {state?.error && <p className="error">{state.error}</p>}

      <button type="submit" disabled={isPending}>
        {isPending ? "Saving..." : "Save"}
      </button>
    </form>
  );
}
```

## Cache and Revalidation

Understand Next.js caching layers and use them strategically:

```tsx
// app/api/posts/route.ts
export const revalidate = 3600; // Revalidate every hour

export async function GET() {
  const posts = await db.posts.findMany();
  return Response.json(posts);
}
```

Use `revalidatePath()` and `revalidateTag()` for on-demand revalidation:

```tsx
"use server";

import { revalidatePath, revalidateTag } from "next/cache";

export async function updatePost(id: string, data: PostData) {
  const post = await db.posts.update({ where: { id }, data });

  // Revalidate specific routes
  revalidatePath(`/posts/${id}`);
  revalidatePath("/posts");

  // Revalidate tagged data
  revalidateTag("posts");

  return post;
}
```

Use `fetch()` with caching options:

```tsx
async function getPosts() {
  const res = await fetch("https://api.example.com/posts", {
    next: { revalidate: 3600, tags: ["posts"] },
  });

  return res.json();
}
```

## Performance Optimization

Apply these patterns to optimize performance:

- Use Server Components by default to reduce JavaScript shipped to the browser
- Implement Suspense boundaries for progressive rendering
- Enable React Compiler for automatic optimization
- Use dynamic imports for large libraries
- Optimize images with `next/image`
- Implement route prefetching for navigation links
- Use streaming responses for large data sets

```tsx
import Image from "next/image";
import dynamic from "next/dynamic";

const HeavyComponent = dynamic(() => import("./HeavyComponent"), {
  loading: () => <div>Loading...</div>,
});

export default function Page() {
  return (
    <div>
      <Image src="/image.jpg" alt="Example" width={400} height={300} />
      <HeavyComponent />
    </div>
  );
}
```

## Security Headers

Configure baseline security headers in `next.config.ts` to protect against common web vulnerabilities:

```typescript
const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-XSS-Protection", value: "0" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
  {
    key: "Content-Security-Policy",
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "font-src 'self'",
      "connect-src 'self'",
      "frame-ancestors 'none'",
    ].join("; "),
  },
];
```

Apply in `next.config.ts`:

```typescript
const nextConfig: NextConfig = {
  async headers() {
    return [{ source: "/(.*)", headers: securityHeaders }];
  },
};
```

### Header Expectations

- **Every** Next.js app must set `X-Content-Type-Options: nosniff` and `X-Frame-Options: DENY` at minimum.
- CSP must start restrictive and widen only with documented justification.
- `Strict-Transport-Security` (HSTS) should be set at the hosting layer (Azure Front Door, Vercel, etc.) rather than in `next.config.ts`.
- Review CSP violations in browser console during development to tune policy before production.

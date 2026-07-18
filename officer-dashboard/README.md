This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## 🚀 Deploying to Vercel

The easiest way to deploy this dashboard for the live hackathon is via [Vercel](https://vercel.com/). 

Because the app relies on Firebase Identity Platform and the FastAPI backend, you **must** configure environment variables in Vercel before the app will work in production.

### Step-by-Step Deployment

1. **Push to GitHub**: Ensure the `officer-dashboard` code is pushed to a GitHub repository.
2. **Import Project**: Log into Vercel and click **Add New... > Project**. Import the GitHub repository.
3. **Configure Framework**: Vercel will automatically detect **Next.js**. Leave the Root Directory as `officer-dashboard` (if this is part of a monorepo) or `/` if it's a standalone repo.
4. **Set Environment Variables**: In the "Environment Variables" section, you must add the exact values found in your local `.env.local` file. 

   **Required Variables:**
   - `NEXT_PUBLIC_FIREBASE_API_KEY`
   - `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
   - `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
   - `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`
   - `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
   - `NEXT_PUBLIC_FIREBASE_APP_ID`
   
   **And crucially, map the API URL to your newly deployed Cloud Run backend:**
   - `NEXT_PUBLIC_API_URL`: `https://<YOUR-CLOUD-RUN-URL>/api/v1` *(Ensure you don't include a trailing slash)*

5. **Deploy**: Click **Deploy**. Vercel will build and serve the static files and API routes.

### Verification
Once deployed, open the Vercel URL. 
- You should be prompted by the Firebase login screen.
- Log in with your test officer credentials.
- Confirm that the case queue populates with data from the real backend.
- *(If the list doesn't load or throws an API error, double-check that `NEXT_PUBLIC_API_URL` is set correctly and the Cloud Run container is healthy!)*

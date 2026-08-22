# Revenue Recovery MVP V1

## North Star
Recover revenue from leads the business already receives.

## Frozen V1 flow
Lead enters -> classify -> respond -> follow up -> detect opportunity -> human handoff -> won/lost -> attribute revenue.

## In scope
- Lead capture
- Fast response
- Qualification
- Lead scoring
- Follow-up
- Revenue Recovery
- Hot-lead detection
- Next Best Action
- Human handoff
- Won/lost outcome
- Generated/recovered revenue

## Out of scope
- Giant CRM
- AI telephony
- Funnels/websites
- Billing
- Visual builder
- Multi-agent universe
- Multiple verticals
- Vanity dashboards
- New-lead prospecting/enrichment in the first slice

## Architecture
- Frontend: Vercel
- Backend/agent: Hetzner
- Database: self-managed PostgreSQL
- Temporary orchestration: n8n
- Model routing: OpenRouter
- Existing agent: preserve and integrate; do not duplicate.

## Core metrics
1. Leads attended
2. Opportunities recovered
3. Sales generated/recovered
4. Revenue generated/recovered

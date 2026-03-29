require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { GoogleGenAI } = require('@google/genai');

const app = express();
const port = Number(process.env.PORT || 3000);
const model = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY;

app.use(cors());
app.use(express.json());

const DOMAIN_DEFINITIONS = {
  sleep_daily: {
    label: 'Basic Functioning - Sleep & Daily Functioning',
    priority: 1,
    questions: ['q4'],
    crisis: false,
    lowFriction:
      'Tonight, set a strict no-screens rule for 1 hour before bed and place a glass of water where you will see it when you wake up.',
    resourceType: 'healthClinic',
    defaultResourceName: 'University Health Clinic',
  },
  mood_functioning: {
    label: 'Basic Functioning - Anxiety, Mood & Daily Functioning',
    priority: 1,
    questions: ['q6'],
    crisis: true,
    lowFriction:
      'For the next 10 minutes, do only the next basic task in front of you: drink water, eat a simple snack, or sit somewhere quiet and steady your breathing.',
    resourceType: 'counseling',
    defaultResourceName: 'University Counseling Center',
  },
  homesickness: {
    label: 'Social & Cultural Integration - Homesickness',
    priority: 2,
    questions: ['q1'],
    crisis: false,
    lowFriction:
      'Schedule one dedicated 30-minute video call home this week, then mute unstructured hometown social scrolling for the rest of the day.',
    resourceType: 'internationalOffice',
    defaultResourceName: 'International Student Office Event Calendar',
  },
  isolation: {
    label: 'Social & Cultural Integration - Isolation',
    priority: 2,
    questions: ['q2'],
    crisis: false,
    lowFriction:
      'Pick one person you already know, even a little, and send a short message asking to meet for tea, lunch, or a quick walk this week.',
    resourceType: 'peerSupport',
    defaultResourceName: 'Peer Support Group for International Students',
  },
  culture_shock: {
    label: 'Social & Cultural Integration - Culture Shock',
    priority: 2,
    questions: ['q5'],
    crisis: false,
    lowFriction:
      'Choose one familiar routine from home to repeat this week, like a meal, music playlist, prayer, or evening check-in, to create a sense of stability.',
    resourceType: 'internationalOffice',
    defaultResourceName: 'International Student Office Coffee Hour',
  },
  academic_overwhelm: {
    label: 'Academic & Executive Functioning - Academic Overwhelm',
    priority: 3,
    questions: ['q3'],
    crisis: false,
    lowFriction:
      'Use one 25-minute Pomodoro sprint on the single assignment that feels most stuck, then stop and reassess instead of trying to fix everything at once.',
    resourceType: 'tutoring',
    defaultResourceName: 'Academic Tutoring Center',
  },
};

const recommendationSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    acknowledgement: { type: 'string' },
    actions: {
      type: 'array',
      minItems: 2,
      maxItems: 2,
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          title: { type: 'string' },
          text: { type: 'string' },
          resourceName: { type: ['string', 'null'] },
        },
        required: ['title', 'text', 'resourceName'],
      },
    },
    safetyNote: { type: ['string', 'null'] },
  },
  required: ['acknowledgement', 'actions', 'safetyNote'],
};

function validateScores(scores) {
  const expected = ['q1', 'q2', 'q3', 'q4', 'q5', 'q6'];

  if (!scores || typeof scores !== 'object') {
    return 'Scores are required.';
  }

  for (const key of expected) {
    const value = scores[key];
    if (!Number.isInteger(value) || value < 1 || value > 5) {
      return `Score ${key} must be an integer from 1 to 5.`;
    }
  }

  return null;
}

function normalizeTrend(trends, questionIds) {
  if (!trends || typeof trends !== 'object') {
    return 'No trend data provided.';
  }

  const matching = questionIds
    .map((questionId) => trends[questionId])
    .filter(Boolean);

  return matching.length > 0 ? matching.join(', ') : 'No trend data provided.';
}

function resolveResource(resourceType, campusResources, fallbackName) {
  const resource = campusResources?.[resourceType];

  return {
    name: resource?.name || fallbackName,
  };
}

function scoreForDomain(domain, scores) {
  return Math.max(...domain.questions.map((questionId) => scores[questionId] || 0));
}

function selectPriorityDomain(scores) {
  const flaggedDomains = Object.entries(DOMAIN_DEFINITIONS)
    .map(([key, domain]) => ({
      key,
      ...domain,
      score: scoreForDomain(domain, scores),
    }))
    .filter((domain) => domain.score >= 4)
    .sort((left, right) => {
      if (left.priority !== right.priority) {
        return left.priority - right.priority;
      }
      return right.score - left.score;
    });

  return flaggedDomains[0] || null;
}

function buildFallbackRecommendation({ studentName, priorityDomain, resource, trend }) {
  const namePrefix = studentName ? `${studentName}, ` : '';
  const acknowledgement = `${namePrefix}it makes sense that ${priorityDomain.label.toLowerCase()} feels heavy right now, especially if this has been ${trend.toLowerCase()}.`;
  const safetyNote =
    priorityDomain.crisis && priorityDomain.score === 5
      ? 'If you feel unsafe or unable to function, contact your campus 24/7 crisis line or local emergency support now.'
      : null;

  return {
    acknowledgement,
    actions: [
      {
        title: 'Start with one low-friction step',
        text: priorityDomain.lowFriction,
        resourceName: null,
      },
      {
        title: 'Use one campus support option',
        text: `Open ${resource.name} and take the smallest next step, like checking hours, reviewing services, or booking one brief appointment or event.`,
        resourceName: resource.name,
      },
    ],
    safetyNote,
  };
}

async function generateRecommendationWithGemini({
  studentName,
  priorityDomain,
  trend,
  resource,
}) {
  if (!apiKey) {
    throw new Error('Missing GEMINI_API_KEY in server environment.');
  }

  const ai = new GoogleGenAI({ apiKey });
  const prompt = [
    'Role: You are an empathetic, concise academic and wellness advisor for international students.',
    `Student Name: ${studentName || 'Student'}`,
    `Current Priority Flag: ${priorityDomain.label}`,
    `Severity Score: ${priorityDomain.score}/5`,
    `Trend: ${trend}`,
    'Directives:',
    '- Write one validating sentence without diagnosing.',
    '- Provide exactly TWO actions.',
    '- Action 1 must be the low-friction self-guided step provided below.',
    '- Action 2 must direct the student to the campus resource provided below.',
    '- Do not address lower-priority issues.',
    '- Keep the tone brief, supportive, and structured.',
    '- Avoid toxic positivity.',
    '- If severity is 5 and the domain is mood/functioning, include a crisis line style safety note.',
    `Low-friction action: ${priorityDomain.lowFriction}`,
    `Campus resource name: ${resource.name}`,
    'Return JSON only.',
  ].join('\n');

  const response = await ai.models.generateContent({
    model,
    contents: prompt,
    config: {
      responseMimeType: 'application/json',
      responseJsonSchema: recommendationSchema,
      temperature: 0.4,
    },
  });

  return JSON.parse(response.text);
}

app.get('/health', (req, res) => {
  res.json({
    ok: true,
    geminiConfigured: Boolean(apiKey),
    model,
  });
});

app.post('/api/recommendations', async (req, res) => {
  const { studentName, scores, trends, campusResources } = req.body || {};
  const scoreError = validateScores(scores);

  if (scoreError) {
    return res.status(400).json({ error: scoreError });
  }

  const priorityDomain = selectPriorityDomain(scores);

  if (!priorityDomain) {
    return res.json({
      triage: {
        status: 'stable',
        message: 'No high-priority domain was flagged at a 4 or 5 this round.',
      },
      recommendation: {
        acknowledgement:
          'You do not appear to have a top-priority concern from this survey right now, but staying connected to small routines and support still matters.',
        actions: [
          {
            title: 'Keep one steady routine',
            text: 'Pick one supportive habit to repeat this week, such as a regular bedtime, one shared meal, or one check-in with someone you trust.',
            resourceName: null,
            resourceUrl: null,
          },
          {
            title: 'Know your support options',
            text: 'Save your campus support links now so they are easy to use later if stress increases.',
            resourceName: null,
            resourceUrl: null,
          },
        ],
        safetyNote: null,
      },
    });
  }

  const trend = normalizeTrend(trends, priorityDomain.questions);
  const resource = resolveResource(
    priorityDomain.resourceType,
    campusResources,
    priorityDomain.defaultResourceName,
  );

  const fallbackRecommendation = buildFallbackRecommendation({
    studentName,
    priorityDomain,
    resource,
    trend,
  });

  try {
    const recommendation = await generateRecommendationWithGemini({
      studentName,
      priorityDomain,
      trend,
      resource,
    });

    return res.json({
      triage: {
        status: 'priority_flagged',
        priorityFlag: priorityDomain.label,
        severityScore: priorityDomain.score,
        trend,
      },
      recommendation,
    });
  } catch (error) {
    console.error('Gemini recommendation error:', error);

    return res.status(200).json({
      triage: {
        status: 'priority_flagged',
        priorityFlag: priorityDomain.label,
        severityScore: priorityDomain.score,
        trend,
      },
      recommendation: fallbackRecommendation,
      warning: 'Gemini response unavailable, so a local fallback recommendation was returned.',
    });
  }
});

app.listen(port, () => {
  console.log(`Sathi local AI server listening on http://localhost:${port}`);
});

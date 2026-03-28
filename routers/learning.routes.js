import express from 'express';

import {
  getCourseMap,
  getCourses,
  getQuizQuestions,
  getSubtopicRevisionQuestions,
  submitQuizAnswers,
} from '../controllers/learning.controller.js';

const router = express.Router();

router.get('/courses', getCourses);
router.get('/courses/:courseId/map', getCourseMap);
router.get('/quizzes/:quizId/questions', getQuizQuestions);
router.post('/quizzes/:quizId/submit', submitQuizAnswers);
router.get('/subtopics/:subtopicId/revision', getSubtopicRevisionQuestions);

export default router;

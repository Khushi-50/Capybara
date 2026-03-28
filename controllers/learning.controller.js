import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';

import { Chapter } from '../models/chapter.model.js';
import { Course } from '../models/course.model.js';
import { Question } from '../models/questions.models,.js';
import { Quiz } from '../models/quiz.schema.js';
import { Subtopic } from '../models/subtopic.model.js';
import { UserProgress } from '../models/userprogress.model.js';

function getTokenFromRequest(req) {
  // frontend now knows who is the sue 
  const authHeader = req.headers.authorization;
  const bearerToken = authHeader?.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;
  return req.cookies?.token || bearerToken || null;
}

function getUserIdFromRequest(req) {
  const token = getTokenFromRequest(req);
  if (!token || !process.env.JWT_SECRET) {
    return null;
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return decoded.id || null;
  } catch {
    return null;
  }
}

function requireUserId(req, res) {
  const userId = getUserIdFromRequest(req);

  if (!userId) {
    res.status(401).json({ message: 'Unauthorized' });
    return null;
  }

  return userId;
}

function buildQuestionProgressMap(progressDocs) {
  const map = new Map();

  for (const progress of progressDocs) {
    map.set(String(progress.question_id), progress);
  }

  return map;
}

// cslklrd by ftnt end when we need to check users courses
export const getCourses = async (req, res) => {
  try {
    const courses = await Course.find()
      .select('title slug description total_chapters thumbnail')
      .sort({ title: 1 })
      .lean();

    res.status(200).json({ courses });
  } catch (error) {
    console.error('Get courses error:', error);
    res.status(500).json({ message: 'Failed to fetch courses.' });
  }
};

export const getCourseMap = async (req, res) => {
  try {
    const { courseId } = req.params;

    const courseQuery = mongoose.isValidObjectId(courseId) ? { _id: courseId } : { slug: courseId };
    const course = await Course.findOne(courseQuery).select('title slug description total_chapters thumbnail').lean();

    if (!course) {
      return res.status(404).json({ message: 'Course not found.' });
    }

    const chapters = await Chapter.find({ course_id: course._id })
      .sort({ chapter_number: 1 })
      .lean();
    const chapterIds = chapters.map((chapter) => chapter._id);

    const subtopics = await Subtopic.find({ chapter_id: { $in: chapterIds } })
      .sort({ order: 1 })
      .lean();
    const subtopicIds = subtopics.map((subtopic) => subtopic._id);

    const quizzes = await Quiz.find({ subtopic_id: { $in: subtopicIds } })
      .sort({ quiz_number: 1 })
      .lean();
    const quizIds = quizzes.map((quiz) => quiz._id);

    const questions = await Question.find({ quiz_id: { $in: quizIds } })
      .select('quiz_id question_number')
      .sort({ question_number: 1 })
      .lean();

    const userId = getUserIdFromRequest(req);
    let questionProgressMap = new Map();

    if (userId && questions.length > 0) {
      const progressDocs = await UserProgress.find({
        user_id: userId,
        question_id: { $in: questions.map((question) => question._id) },
      }).lean();

      questionProgressMap = buildQuestionProgressMap(progressDocs);
    }

    const questionsByQuiz = new Map();
    for (const question of questions) {
      const key = String(question.quiz_id);
      if (!questionsByQuiz.has(key)) {
        questionsByQuiz.set(key, []);
      }
      questionsByQuiz.get(key).push(question);
    }

    const quizzesBySubtopic = new Map();
    for (const quiz of quizzes) {
      const quizQuestions = questionsByQuiz.get(String(quiz._id)) || [];
      const completedQuestions = quizQuestions.filter((question) => {
        const progress = questionProgressMap.get(String(question._id));
        return progress?.is_correct;
      }).length;

      const failedQuestions = quizQuestions.filter((question) => {
        const progress = questionProgressMap.get(String(question._id));
        return progress && !progress.is_correct;
      }).length;

      const totalQuestions = quizQuestions.length;
      const isCompleted = totalQuestions > 0 && completedQuestions === totalQuestions;
      const isUnlocked = totalQuestions === 0 || completedQuestions > 0 || failedQuestions > 0 || !userId;

      const quizNode = {
        id: quiz._id,
        quiz_number: quiz.quiz_number,
        quiz_title: quiz.quiz_title,
        total_xp: quiz.total_xp,
        total_questions: totalQuestions,
        completed_questions: completedQuestions,
        failed_questions: failedQuestions,
        is_completed: isCompleted,
        is_unlocked: isUnlocked,
      };

      const key = String(quiz.subtopic_id);
      if (!quizzesBySubtopic.has(key)) {
        quizzesBySubtopic.set(key, []);
      }
      quizzesBySubtopic.get(key).push(quizNode);
    }

    const subtopicsByChapter = new Map();
    for (const subtopic of subtopics) {
      const subtopicQuizzes = quizzesBySubtopic.get(String(subtopic._id)) || [];
      const totalQuizzes = subtopicQuizzes.length;
      const completedQuizzes = subtopicQuizzes.filter((quiz) => quiz.is_completed).length;

      const subtopicNode = {
        id: subtopic._id,
        order: subtopic.order,
        subtopic_name: subtopic.subtopic_name,
        total_quizzes: totalQuizzes,
        completed_quizzes: completedQuizzes,
        is_completed: totalQuizzes > 0 && completedQuizzes === totalQuizzes,
        is_unlocked: !userId || totalQuizzes === 0 || subtopicQuizzes.some((quiz) => quiz.is_unlocked),
        quizzes: subtopicQuizzes,
      };

      const key = String(subtopic.chapter_id);
      if (!subtopicsByChapter.has(key)) {
        subtopicsByChapter.set(key, []);
      }
      subtopicsByChapter.get(key).push(subtopicNode);
    }

    const chapterNodes = chapters.map((chapter) => {
      const chapterSubtopics = subtopicsByChapter.get(String(chapter._id)) || [];
      const totalSubtopics = chapterSubtopics.length;
      const completedSubtopics = chapterSubtopics.filter((subtopic) => subtopic.is_completed).length;

      return {
        id: chapter._id,
        chapter_number: chapter.chapter_number,
        chapter_name: chapter.chapter_name,
        description: chapter.description,
        total_subtopics: totalSubtopics,
        completed_subtopics: completedSubtopics,
        is_completed: totalSubtopics > 0 && completedSubtopics === totalSubtopics,
        is_unlocked: !userId || totalSubtopics === 0 || chapterSubtopics.some((subtopic) => subtopic.is_unlocked),
        subtopics: chapterSubtopics,
      };
    });

    res.status(200).json({
      course: {
        id: course._id,
        title: course.title,
        slug: course.slug,
        description: course.description,
        total_chapters: course.total_chapters,
        thumbnail: course.thumbnail,
      },
      chapters: chapterNodes,
    });
  } catch (error) {
    console.error('Get course map error:', error);
    res.status(500).json({ message: 'Failed to fetch course map.' });
  }
};

export const getQuizQuestions = async (req, res) => {
  try {
    const { quizId } = req.params;

    const quiz = await Quiz.findById(quizId).lean();
    if (!quiz) {
      return res.status(404).json({ message: 'Quiz not found.' });
    }

    const questions = await Question.find({ quiz_id: quiz._id })
      .sort({ question_number: 1 })
      .lean();

    res.status(200).json({
      quiz: {
        id: quiz._id,
        subtopic_id: quiz.subtopic_id,
        quiz_number: quiz.quiz_number,
        quiz_title: quiz.quiz_title,
        total_xp: quiz.total_xp,
      },
      questions: questions.map((question) => ({
        id: question._id,
        question_number: question.question_number,
        question_text: question.question_text,
        options: question.options,
        correct_answer: question.correct_answer,
        xp_value: question.xp_value,
      })),
    });
  } catch (error) {
    console.error('Get quiz questions error:', error);
    res.status(500).json({ message: 'Failed to fetch quiz questions.' });
  }
};

export const submitQuizAnswers = async (req, res) => {
  try {
    const userId = requireUserId(req, res);
    if (!userId) {
      return;
    }

    const { quizId } = req.params;
    const { answers } = req.body;

    if (!Array.isArray(answers) || answers.length === 0) {
      return res.status(400).json({ message: 'Answers array is required.' });
    }

    const questions = await Question.find({ quiz_id: quizId }).lean();
    if (questions.length === 0) {
      return res.status(404).json({ message: 'Quiz or questions not found.' });
    }

    const questionMap = new Map(questions.map((question) => [String(question._id), question]));
    const existingProgress = await UserProgress.find({
      user_id: userId,
      question_id: { $in: questions.map((question) => question._id) },
    });
    const progressMap = new Map(existingProgress.map((item) => [String(item.question_id), item]));

    const results = [];
    let earnedXp = 0;

    for (const answerItem of answers) {
      const question = questionMap.get(String(answerItem.questionId));
      if (!question) {
        continue;
      }

      const isCorrect = answerItem.selectedAnswer === question.correct_answer;
      if (isCorrect) {
        earnedXp += question.xp_value;
      }

      const existingItem = progressMap.get(String(question._id));
      if (existingItem) {
        existingItem.attempts_count += 1;
        existingItem.is_correct = isCorrect;
        existingItem.status = isCorrect ? 'completed' : 'failed';
        existingItem.last_attempted = new Date();
        await existingItem.save();
      } else {
        await UserProgress.create({
          user_id: userId,
          question_id: question._id,
          attempts_count: 1,
          is_correct: isCorrect,
          status: isCorrect ? 'completed' : 'failed',
          last_attempted: new Date(),
        });
      }

      results.push({
        question_id: question._id,
        selected_answer: answerItem.selectedAnswer,
        correct_answer: question.correct_answer,
        is_correct: isCorrect,
        xp_value: isCorrect ? question.xp_value : 0,
      });
    }

    const totalQuestions = questions.length;
    const correctCount = results.filter((item) => item.is_correct).length;

    res.status(200).json({
      quiz_id: quizId,
      total_questions: totalQuestions,
      attempted_questions: results.length,
      correct_answers: correctCount,
      incorrect_answers: results.length - correctCount,
      earned_xp: earnedXp,
      results,
    });
  } catch (error) {
    console.error('Submit quiz answers error:', error);
    res.status(500).json({ message: 'Failed to save quiz progress.' });
  }
};

export const getSubtopicRevisionQuestions = async (req, res) => {
  try {
    const userId = requireUserId(req, res);
    if (!userId) {
      return;
    }

    const { subtopicId } = req.params;
    const subtopic = await Subtopic.findById(subtopicId).lean();
    if (!subtopic) {
      return res.status(404).json({ message: 'Subtopic not found.' });
    }

    const quizzes = await Quiz.find({ subtopic_id: subtopic._id }).select('_id').lean();
    const questions = await Question.find({ quiz_id: { $in: quizzes.map((quiz) => quiz._id) } })
      .sort({ question_number: 1 })
      .lean();

    const failedProgress = await UserProgress.find({
      user_id: userId,
      question_id: { $in: questions.map((question) => question._id) },
      is_correct: false,
    }).lean();

    const failedQuestionIds = new Set(failedProgress.map((item) => String(item.question_id)));
    const revisionQuestions = questions
      .filter((question) => failedQuestionIds.has(String(question._id)))
      .map((question) => ({
        id: question._id,
        question_number: question.question_number,
        question_text: question.question_text,
        options: question.options,
        correct_answer: question.correct_answer,
        xp_value: question.xp_value,
      }));

    res.status(200).json({
      subtopic: {
        id: subtopic._id,
        subtopic_name: subtopic.subtopic_name,
        order: subtopic.order,
      },
      total_revision_questions: revisionQuestions.length,
      questions: revisionQuestions,
    });
  } catch (error) {
    console.error('Get revision questions error:', error);
    res.status(500).json({ message: 'Failed to fetch revision questions.' });
  }
};
